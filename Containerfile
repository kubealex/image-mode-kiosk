FROM registry.redhat.io/rhel10/rhel-bootc:latest

# Install RPMs and clean up the cache in the same layer to optimize the build process and reduce the image size by minimizing the number of layers created during the build process. This also helps in reducing the overall image size by minimizing the number of intermediate layers created during the build process.
# Install GNOME and enable graphical.target as default
# Remove GNOME initial setup and tour to avoid first boot pop-ups

RUN dnf config-manager --set-enabled edge-manager-1.1-for-rhel-10-$(uname -m)-rpms && \
    dnf -y install tmux flightctl-agent  mkpasswd git firefox unzip && \
    dnf group install -y --allowerasing GNOME Fonts && \
    dnf remove -y gnome-initial-setup gnome-tour && \
    dnf clean all

RUN pass=$(mkpasswd --method=SHA-512 --rounds=4096 redhat) && useradd -m -G wheel redhat -p $pass
RUN echo "%wheel        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/wheel-sudo

RUN systemctl set-default graphical.target && \
    systemctl enable flightctl-agent.service && \
    systemctl mask bootc-fetch-apply-updates.timer

# COPY the auth.json to enable the image to authenticate with GHCR
#COPY ./auth.json /etc/ostree/

# Registering machine to Red Hat Insights
# Populate the .rhc_connect_credentials file with RHC_ACT_KEY=activation key and RHC_ORG_ID=organization id.
# See https://console.redhat.com/insights/connector/activation-keys
# COPY rhc-connect.service /usr/lib/systemd/system/rhc-connect.service
# COPY .rhc_connect_credentials /etc/rhc/.rhc_connect_credentials
# RUN systemctl enable rhc-connect && touch /etc/rhc/.run_rhc_connect_next_boot

# Configure the display resolution using tmpfiles to persist the default configuration.
# May have to be adjusted based on the monitor you are using. The current configuration is for 800x600 QEMU VM resolution, where the arcade game was full screen.
#COPY monitors.xml /usr/share/gdm/monitors.xml

# Turning off Automatic Overview when a user is logged into - ADD extracts the archive and creates intermediate directories.
# ADD dash-to-dock.tar.gz /usr/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com/

# Download dash-to-dock to /usr for tmpfiles provisioning
RUN mkdir -p /usr/share/dash-to-dock && \
    curl -L https://github.com/micheleg/dash-to-dock/releases/download/extensions.gnome.org-v103/dash-to-dock@micxgx.gmail.com.zip \
        -o /tmp/dash-to-dock.zip && \
    unzip /tmp/dash-to-dock.zip -d /usr/share/dash-to-dock && \
    rm /tmp/dash-to-dock.zip

COPY config.yaml /etc/flightctl/config.yaml
COPY --chmod=644 etc/ etc/
COPY --chmod=644 usr/ usr/

RUN dconf update