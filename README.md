# youwol-keycloak-theme

Keycloak theme for Youwol cluster.

- [Publish Youwol theme docker image](#publish-youwol-theme-docker-image)
- [Deploy Keycloak with Youwol theme](#deploy-keycloak-with-youwol-theme)
- [Use a specific theme](#use-a-specific-theme)
- [Development](#development)
    * [Run Keycloak docker image for development](#run-keycloak-docker-image-for-development)
    * [Create a new theme and extend existing ones](#create-a-new-theme-and-extend-existing-ones)
        + [Welcome theme](#welcome-theme)
        + [Login theme](#login-theme)
        + [Account theme](#account-theme)
        + [Admin Console theme](#admin-console-theme)
        + [Email theme](#email-theme)
    * [Extract the builtin themes](#extract-the-builtin-themes)

## Publish Youwol theme docker image

*NB: building docker image is only needed for publishing, development can be done by directly editing the `./theme`
directory when this directory is mounted in a Keycloak container. See [below](#run-keycloak-docker-image-for-development).*

Simply run from this repository directory
```shell
docker build -t youwol-keycloak-theme:0.1.0
docker tag youwol-keycloak-theme:0.1.0 registry.gitlab.com/youwol/platform/youwol-keycloak-theme:0.1.0
docker push registry.gitlab.com/youwol/platform/youwol-keycloak-theme:0.1.0
```


## Deploy Keycloak with Youwol theme

This repository docker image will be used as an init container in kubernetes PodTemplate,
simply copying contents of its directory `./theme/` into a shared volume mounted into Keycloak container under 
`/opt/keycloak/themes/youwol` :
```yaml
      spec:
        initContainers:
          - name: deploy-youwol-keycloak-theme
            image: youwol-keycloak-theme:0.0.1
            command:
              - sh
            args:
              - -c
              - |
                echo "Copying theme …"
                cp -R /theme/* /target
            volumeMounts:
              - name: youwol-keycloak-theme
                mountPath: /target
        containers:
          - volumeMounts:
              - name: youwol-keycloak-theme
                mountPath: /opt/keycloak/themes/youwol
        volumes:
          - name: youwol-keycloak-theme
            emptyDir: {}
```


## Use a specific theme


Except for the [`welcome` theme](#welcome-theme) (defined at startup with the option `spi-theme-welcome-theme`),
these different types are configured for each realm:

`(welcome page) Administration Console => (left menu) Realm settings => (tab) Themes`



## Development

Also see official documentation : https://www.keycloak.org/docs/19.0.3/server_development/#_themes

### Run Keycloak docker image for development

This will launch a keycloak 19.0.3 container, ready for themes development:
* listen on port 8080 (i.e. access at http://localhost:8080/)
* host directory `./theme/` mounted into `/opt/keycloak/themes/youwol`: will define theme `youwol` from host directory
* env vars `KEYCLOAK_ADMIN` and `KEYCLOAK_ADMIN_PASSWORD`: initial account, for administration
* command argument `start-dev`: start in dev mode (no security check, H2 database, etc…)
* command arguments `spi-theme-cache-*`, `spi-theme-static-max-age`: disable themes caching
* command argument `spi-theme-welcome-theme=youwol`: configure theme `youwol` for [welcome page](#welcome-theme)

```shell
docker run --rm --name kc_container \
  -p 8080:8080 \
  -v $(pwd)/theme/:/opt/keycloak/themes/youwol \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:19.0.3 start-dev \
  --spi-theme-static-max-age=-1 \
  --spi-theme-cache-themes=false \
  --spi-theme-cache-templates=false
  --spi-theme-welcome-theme=youwol
```

Once the container is running, just create a new realm, add a new user to this realm, and [configure](#use-a-specific-theme)
this new realm and the `master` realm to used the `youwol` theme.

### Create a new theme and extend existing ones

Each aspect of Keycloak can be customized independently, and a theme directory can provide one or more of these
aspects by having any of the following subdirectories :
- [welcome](#welcome-theme)
- [login](#login-theme)
- [account](#account-theme)
- [admin](#admin-console-theme)
- [email](#email-theme)

Each of these directories define a theme using the following files:
* `./*.ftl` : HTML templates (and text templates for [email](#email-theme)), using [Freemarker](https://freemarker.apache.org)
* `./resources/` : Static resources (images, css, js, etc…)
* `./messages/messages_<lang>.properties` : (localized) [Messages bundles](https://www.keycloak.org/docs/19.0.3/server_development/#messages)
* `./theme.properties` : [Theme properties](https://www.keycloak.org/docs/19.0.3/server_development/#theme-properties)

Rather than defining all these elements, a custom theme can reuse an existing theme (i.e. a builtin theme) and only 
define some new elements (or override existing ones) by extending this existing theme:
```properties
# In theme.properties
parent=<existing theme>
```

To facilitate customization, reduce maintenance, and limit security risks:
* new themes should extend builtin ones (i.e. `parent=<builtin>` in `./theme.properties`)
* messages should not be modified (no messages defined in customized theme)
* JS & HTML templates should not be modified (except for welcome theme)

For reference, the builtin themes are committed in this repository under the directory `./builtins/<keycloak version>/`


### Customizable aspects of Keycloak

#### Welcome theme

For the (single) welcome page:
* In production environnement : https://platform.youwol.com/auth/
* Docker image : http://localhost:8080/

*NB: There is no way to disable this page, so it should be fully customized for Youwol, including HTML template.*

#### Login theme

For login, logout, OTP input, errors, etc. Try out these various actions.
For security reason this theme should be based on a builtin theme and change restricted to css and image.

*NB: When no specific realm can be determined (i.e. for some errors pages), the `master` realm login theme is used.*

#### Account theme

For account management. For security reason this theme should be based on a builtin theme and change restricted to 
css and image:
* In production environment : https://platform.youwol.com/auth/realms/youwol/account/
* Docker image : http://localhost:8080/realms/master/account/


#### Admin Console theme

For the administration of keycloak. For now there is no user facing pages, so no customization is necessary:
* In production environment : http://platform.youwol.com/auth/admin/master/console
* Docker image : http://localhost:8080/admin/master/console

#### Email theme

Template for sending email. The default theme should be enough.


### Extract the builtin themes

Builtins themes are available in keycloak official image, packaged as a jar archive. Only the theme directory of 
this archive is of interest.

For instance, for keycloak 19.0.3 (assuming these command lines are run from repository)

```shell
# Repository directory
TARGET_DIR=$(pwd)/builtins/19.0.3
mkdir -p $TARGET_DIR

# Temp directory for archive decompression
WORKDIR=/tmp/kc_builtin_themes
mkdir -p $WORKDIR

# Run a keycloak container and extract JAR archive
docker run --detach --rm --name kc_container quay.io/keycloak/keycloak:19.0.3 start-dev
docker cp kc_container:/opt/keycloak/lib/lib/main/org.keycloak.keycloak-themes-19.0.3.jar $WORKDIR
docker stop kc_container

# Decompress archive and copy themes directories
cd $WORKDIR
unzip org.keycloak.keycloak-themes-19.0.3.jar
mv $WORKDIR/theme/* $TARGET_DIR
```
