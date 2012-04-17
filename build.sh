 #!/bin/bash         

read -p "GIT comment : " gc
echo ""

echo "Building..."
git add .
git commit -m "Update $gc"
git push git@github.com:ugik/Text7.git master
git push heroku master

