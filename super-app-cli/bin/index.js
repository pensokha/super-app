#!/usr/bin/env node

import { Command } from 'commander';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';
import { execSync, spawn } from 'child_process';
import ora from 'ora';
import { fileURLToPath } from 'url';

const program = new Command();

// In ES Modules, __dirname is not directly available.
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// --- Helper Functions ---

/**
 * Executes a shell command synchronously and handles errors.
 * @param {string} command - The command to execute.
 * @param {string} cwd - The current working directory for the command.
 * @param {string} successMessage - Message to display on success.
 * @param {string} errorMessage - Message to display on error.
 */
function runCommand(command, cwd, successMessage, errorMessage) {
  const spinner = ora(chalk.cyan(successMessage.replace('...', ''))).start();
  try {
    execSync(command, { stdio: 'pipe', cwd });
    spinner.succeed(chalk.green(successMessage));
  } catch (error) {
    spinner.fail(chalk.red(errorMessage));
    console.error(chalk.red(error.stderr ? error.stderr.toString() : error.message));
    process.exit(1);
  }
}

/**
 * Executes a shell command asynchronously and streams output.
 * @param {string} command - The command to execute.
 * @param {string[]} args - Arguments for the command.
 * @param {string} cwd - The current working directory.
 */
function runInteractiveCommand(command, args, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: 'inherit', // Stream output to parent process
      cwd,
      shell: true, // Use shell to allow commands like 'npm' to be found
    });

    child.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(`Command failed with code ${code}`));
      } else {
        resolve();
      }
    });

    child.on('error', (err) => {
      reject(err);
    });
  });
}

// --- CLI Commands ---

program
  .name('super-app-cli')
  .description('CLI for managing Super App Mini Apps')
  .version('1.0.0');

// 'create' command
program
  .command('create <appName>')
  .description('Create a new Mini App from a template')
  .option('-t, --template <templateName>', 'Specify a template (e.g., react-starter)', 'react-starter')
  .action(async (appName, options) => {
    const templatePath = path.join(__dirname, '..', 'templates', options.template);
    const appPath = path.join(process.cwd(), appName);

    console.log(chalk.blue(`\nCreating a new Mini App: ${appName}...\n`));

    // 1. Check if template exists
    if (!fs.existsSync(templatePath)) {
      console.error(chalk.red(`Error: Template '${options.template}' not found at ${templatePath}`));
      process.exit(1);
    }

    // 2. Check if app directory already exists
    if (fs.existsSync(appPath)) {
      console.error(chalk.red(`Error: Directory '${appName}' already exists. Please choose a different name or delete the existing directory.`));
      process.exit(1);
    }

    // 3. Copy template
    runCommand(
      `cp -R ${templatePath} ${appPath}`,
      process.cwd(),
      `Copied template '${options.template}' to '${appName}'`,
      `Failed to copy template for '${appName}'`
    );

    // 4. Update package.json
    const packageJsonPath = path.join(appPath, 'package.json');
    const packageJson = fs.readJsonSync(packageJsonPath);
    packageJson.name = appName;
    packageJson.version = '0.1.0';
    packageJson.private = true;
    packageJson.homepage = '.'; // Ensure relative paths for local loading
    fs.writeJsonSync(packageJsonPath, packageJson, { spaces: 2 });
    console.log(chalk.green(`Updated package.json for '${appName}'`));

    // 5. Install dependencies
    console.log(chalk.blue(`\nInstalling dependencies for '${appName}'... This might take a moment.`));
    await runInteractiveCommand(
      'npm', ['install'], appPath
    ).then(() => {
      console.log(chalk.green(`Dependencies installed successfully for '${appName}'`));
    }).catch((error) => {
      console.error(chalk.red(`Failed to install dependencies for '${appName}': ${error.message}`));
      process.exit(1);
    });

    console.log(chalk.green(`\nMini App '${appName}' created successfully!`));
    console.log(chalk.yellow(`\nNext steps:\n  cd ${appName}`));
    console.log(chalk.yellow(`  super-app-cli serve`));
  });

// 'serve' command
program
  .command('serve')
  .description('Start the development server for the current Mini App')
  .action(async () => {
    const appPath = process.cwd();
    console.log(chalk.blue(`\nStarting development server for Mini App in '${appPath}'...`));
    try {
      await runInteractiveCommand('npm', ['start'], appPath);
    } catch (error) {
      console.error(chalk.red(`Failed to start development server: ${error.message}`));
      process.exit(1);
    }
  });

// 'build' command
program
  .command('build')
  .description('Build the current Mini App for deployment and create a zip archive')
  .option('-o, --output <filename>', 'Specify the output zip filename (e.g., my_app_v1.0.0.zip)')
  .action(async (options) => {
    const appPath = process.cwd();
    const appName = path.basename(appPath);
    const packageJsonPath = path.join(appPath, 'package.json');

    if (!fs.existsSync(packageJsonPath)) {
      console.error(chalk.red(`Error: No package.json found in '${appPath}'. Are you in a Mini App directory?`));
      process.exit(1);
    }

    const packageJson = fs.readJsonSync(packageJsonPath);
    const appVersion = packageJson.version || '0.0.1';
    const outputZipName = options.output || `${appName}_v${appVersion}.zip`;
    const buildDir = path.join(appPath, 'build');
    const outputZipPath = path.join(appPath, outputZipName);

    console.log(chalk.blue(`\nBuilding Mini App '${appName}' (version ${appVersion})...`));

    // 1. Run npm build
    await runInteractiveCommand(
      'npm', ['run', 'build'], appPath
    ).then(() => {
      console.log(chalk.green(`Mini App '${appName}' built successfully.`));
    }).catch((error) => {
      console.error(chalk.red(`Failed to build Mini App '${appName}': ${error.message}`));
      process.exit(1);
    });

    // 2. Create zip archive
    console.log(chalk.blue(`\nCreating zip archive: ${outputZipName}...`));
    try {
      // Ensure the build directory exists
      if (!fs.existsSync(buildDir)) {
        throw new Error(`Build directory not found: ${buildDir}`);
      }

      // Remove existing zip if it exists
      if (fs.existsSync(outputZipPath)) {
        fs.removeSync(outputZipPath);
      }

      // Zip the contents of the build directory
      execSync(`cd ${buildDir} && zip -r ${outputZipPath} .`, { stdio: 'pipe', cwd: appPath }); // Ensure cwd is correct for zip
      console.log(chalk.green(`Zip archive created at: ${outputZipPath}`));
    } catch (error) {
      console.error(chalk.red(`Failed to create zip archive: ${error.message}`));
      process.exit(1);
    }

    console.log(chalk.green(`\nMini App '${appName}' packaged successfully!`));
    console.log(chalk.yellow(`\nTo deploy, upload '${outputZipName}' to your Super App backend.`));
  });

program.parse(process.argv);
