#!/bin/bash

# Navigate to Next.js directory
cd "$(dirname "$0")/electron/servers/nextjs"

# Start Next.js development server
npx next dev -p 3000
