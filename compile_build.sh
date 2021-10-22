cd builds

TODAY=$(date '+%Y-%m-%d')
mkdir releases/$TODAY

mv tmp_build/who-knows-the-news.html tmp_build/index.html
cp -r tmp_build/ releases/$TODAY/
cd releases/$TODAY
rm who-knows-the-news.zip
zip who-knows-the-news.zip index.html *.js *.png *.wasm *.pck *.import
