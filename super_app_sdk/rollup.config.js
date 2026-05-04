const babel = require('@rollup/plugin-babel');

module.exports = {
  input: 'src/index.js',
  output: [
    {
      file: 'dist/index.cjs.js',
      format: 'cjs', // CommonJS for Node.js compatibility
      sourcemap: true,
    },
    {
      file: 'dist/index.esm.js',
      format: 'esm', // ES Module for modern bundlers
      sourcemap: true,
    },
  ],
  plugins: [
    babel({
      babelHelpers: 'bundled',
      exclude: 'node_modules/**',
    }),
  ],
};
