# youwol-keycloak-theme

Build a docker image for deploying Youwol keycloak theme. This image will be used as an init container in kubernetes PodTemplate :
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
