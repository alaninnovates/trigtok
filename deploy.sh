flutter build web --base-href / --release
cd build/web
git add .
git commit -m "Deploy at $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main