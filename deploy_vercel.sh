# #!/bin/bash
# echo "Building Flutter web app..."
# flutter build web --release

# echo "Deploying to Vercel..."
# cd build/web
# vercel deploy --prod


# #!/bin/bash
# echo "Building Flutter web app..."
# flutter build web --release

# echo "Deploying to NEW Vercel project..."
# cd build/web

# vercel deploy --prod \
#   --token=yBDFuOzjwsVbJ000wNTAMrZs \
#   --project=emi_calculator_2

# #!/bin/bash
# echo "Building Flutter web app..."
# flutter build web --release

# echo "Deploying to NEW Vercel project..."
# cd build/web

# # Create temporary .vercel folder for this deploy
# mkdir -p .vercel

# cat <<EOF > .vercel/project.json
# {
#   "projectName": "emi_calculator_2",
#   "orgId": "gopi-markwaves-projects"
# }
# EOF

# vercel deploy --prod --token=yBDFuOzjwsVbJ000wNTAMrZs

# # Clean up after deploy
# rm -rf .vercel

#!/bin/bash
echo "Building Flutter web app..."
flutter build web --release

echo "Deploying to NEW Vercel project..."
cd build/web

# Create temporary .vercel folder for this deploy
mkdir -p .vercel

cat <<EOF > .vercel/project.json
{
  "orgId": "team_80uUe4elWYrZNDhP96zVd2HF",
  "projectId": "prj_TtxzXHpw0qHmI69P9p6mBgQWAdw5",
  "projectName": "emi_calculator_2"
}
EOF

vercel deploy --prod --token=yBDFuOzjwsVbJ000wNTAMrZs

# Clean up after deploy
rm -rf .vercel
