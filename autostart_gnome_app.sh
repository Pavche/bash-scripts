#!/usr/bin/env bash
# Set applications for automatic start
# when a GNOME session is started.
# Works under RHEL 7.3

[ -d "$HOME/.config/autostart" ] || mkdir -p "$HOME/.config/autostart"

pushd /usr/share/applications
cp \
  eog.desktop\
  evince.desktop\
  firefox.desktop\
  gedit.desktop\
  gnome-control-center.desktop\
  gnote.desktop\
  libreoffice-writer.desktop\
  nautilus-classic.desktop\
  org.gnome.gedit.desktop\
  org.gnome.Nautilus.desktop\
  org.gnome.Terminal.desktop\
  $HOME/.config/autostart/
  
popd