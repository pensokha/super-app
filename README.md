Super App with a Mini App architecture is a fantastic and ambitious project. It's the model used by giants like WeChat, Alipay, and Gojek. I decided to use a Flutter shell for the Super App and web technologies (React/Vue) for the Mini Apps is a very common and effective pattern for cross platform application development.


# High-Level Architecture Overview

1. The Super App (The "Shell"): A native-like application built with Flutter. Its primary jobs are:

    - Provide core services: Authentication, User Profile, Payments, Notifications.
    - Discover, load, and manage Mini Apps.
    - Expose native device and core service APIs to the Mini Apps.
    - Provide a consistent UI/UX for navigation and core functions.

The Mini Apps (The "Guests"): These are essentially single-page applications (SPAs) built with React or Vue. They run inside a WebView component within the Flutter Super App. They cannot run on their own.

The Bridge (The "Nervous System"): This is the most critical piece of technology. It's a communication layer that allows the JavaScript code in the Mini App (running in a WebView) to talk to the Dart/Native code in the Flutter Super App, and vice-versa.

# Project structure
- Super App: the shell app for hosting mini app
- Super App backend: backend of super app
- hello world miniapp: sample mini application


# how to package miniapp
    # cd super_app_miniapp
    # npm run build
    # cd build
    # zip -r ../hello_world_v1.1.4.zip .
# how to deploy miniapp to vercel
cd ../hello_world_miniapp
vercel --prod

