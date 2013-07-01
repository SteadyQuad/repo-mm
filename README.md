repo-mm
=======

repo mirror manager

The end goal is to provide a tool manage local mirrors, so you can keep your mind on development, and saving hosting providers from you downloading over-and-over again.

Currently, there is a script called gerrit-mirror.sh. This scripts purpose is to mirror every project publicly listed on gerrit from it's respective git host. This allows you to work remotely - disconnected, or if you have a slow connection when you run the script again, it fetches updates instead of cloning again.

I'm open to suggestion, fork this, make changes to your fork, open a pull request.
If you find a bug, open an issue, or the above pull request method.