#
# Source me to set up ccache with recommended defaults in the current working
# directory.
#
# Assuming you have a repo workspace set up in /var/maru/workspace:
#
#    $ cd /var/maru/workspace
#    $ source ~/scripts/setup-ccache.sh
#

# https://source.android.com/source/initializing.html#optimizing-a-build-environment
export USE_CCACHE=1
export CCACHE_DIR="$(pwd)/.ccache"
prebuilts/misc/linux-x86/ccache/ccache -M 50G
