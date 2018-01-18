#!/bin/sh

# pibamo.sh

# MIT License
# Copyright 2018 Sam Strachan

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# References:     https://github.com/iizukanao/picam
#                 https://github.com/sbs20/picam-setup
#                 https://kamranicus.com/guides/raspberry-pi-3-baby-monitor

# Hardware:       Raspberry Pi Camera Module V2
#                 Adafruit Mini USB Microphone

# Play from Kodi  http://kodi.wiki/view/Internet_video_and_audio_streams#The_.STRM_file_method:

# set -x

cd ~
SERVER=pibamo
PROG="pibamo.sh"

PICAM_DIR=~/picam
SHM_DIR=/run/shm
PID_FILE=${PICAM_DIR}/${PROG}.pid

check_privilege()
{
    root="0"

    if [ "$(sudo id -u)" -ne ${root} ] ; then
        echo "Error: This must be executed with root privileges. Are you a sudoer?"
        exit 1
    fi
}

install_dependencies()
{
    sudo apt-get install -y nginx

    wget -O picam-setup.sh \
            https://raw.githubusercontent.com/sbs20/picam-setup/master/picam-setup.sh && \
        chmod +x picam-setup.sh && \
        ./picam-setup.sh install
}

configure_nginx()
{
    # Output to a temp file as sudo is lost on the redirect
    tmp="~cam-tmp"
    cat << EOF >> ${tmp}
server {
        server_name ${SERVER};
        listen 80;
        index index.m3u8;
        root /var/www/html;
        location / {
                root /run/shm/hls;
        }
}
EOF

    # Then sudo here
    sudo mv ${tmp} /etc/nginx/sites-available/${PROG}
    sudo ln -s /etc/nginx/sites-available/${PROG} /etc/nginx/sites-enabled/${PROG}
    sudo service nginx restart
}

make_directories()
{
    ~/picam-setup.sh directories
}

install_all()
{
    check_privilege
    install_dependencies
    configure_nginx
}

uninstall()
{
    check_privilege
    stop
    sudo rm -f /etc/nginx/sites-available/${PROG}
    sudo rm -f /etc/nginx/sites-enabled/${PROG}
    sudo systemctl restart nginx

    echo "You may also wish to run:"
    echo "    ./picam-setup.sh uninstall"
    echo "    sudo apt-get purge nginx nginx-common"
}

start()
{
    if [ ! -d ${PICAM_DIR} ]; then
        echo "${PICAM_DIR}/ does not exist. Please install first: ./${PROG} install"
        exit 1
    fi

    if [ -e ${PID_FILE} ]; then
        echo "${PROG} is already running."
        exit 1
    fi

    # Make directories
    make_directories

    # This could do with testing. It's a bit of a guess
    alsa_device=$(arecord -l | grep card | sed "s:card \([0-9]\).*device \([0-9]\).*:hw\:\1,\2:")
    cd ${PICAM_DIR}

    hls="-o /run/shm/hls"
    args="${hls} --alsadev ${alsa_device} --rotation 180 --ex auto"
    # --width 720 --height 440 --volume 2"

    ./picam ${args} &
    exit_code=$?

    if [ ${exit_code} -ne 0 ]; then
        echo "Picam exited unexpectedly"
        exit 1
    fi

    pid=$!
    echo ${pid} > ${PID_FILE}
    sleep 2
    echo
    echo "${PROG} started. Go here: http://${SERVER}/"
    echo "Optionally, increase microphone volume with \`alsamixer\`"
}

stop()
{
    if [ -e ${PID_FILE} ]; then
        pid=$(cat ${PID_FILE})
        kill ${pid}
        rm ${PID_FILE}
        echo "Stopped ${PROG}."
    else
        echo "${PROG} is not running."
    fi
}

main()
{
    case $1 in
        install)
            install_all
            ;;

        uninstall)
            uninstall
            ;;

        start)
            start
            ;;

        stop)
            stop
            ;;

        *)
            echo "Usage ${PROG} {install | uninstall | start | stop}"
            ;;

    esac
}

main $1
