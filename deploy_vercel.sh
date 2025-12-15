#!/bin/bash
echo "Building Flutter web app..."
flutter build web --release

echo "Deploying to Vercel..."
cd build/web
vercel deploy --prod
