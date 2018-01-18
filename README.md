# pibamo.sh

Installs and runs [picam](https://github.com/iizukanao/picam) in HLS mode with
[nginx](https://www.nginx.com/) so that you can connect using Kodi / VLC etc to
watch and listen. I suppose you could use this for evil ends - but then you can
always just go and buy a camera yourself. I built this as a simple baby monitor.
It should go without saying that you should not depend on this for the health of
your baby or child, but just in case **please do not**. That said - it does
work!

Inspiration from [Kamranicus](https://kamranicus.com/guides/raspberry-pi-3-baby-monitor)

**This has only been lightly tested. Feedback and issues welcome**

## Run
Here's a one liner to install
```
wget -O pibamo.sh https://raw.githubusercontent.com/sbs20/pibamo/master/pibamo.sh && chmod +x pibamo.sh && ./pibamo.sh install
```
