apiVersion: apps/v1
kind: Deployment
metadata:
  name: pelias-api
spec:
  replicas: 1
  minReadySeconds: 10
  selector:
    matchLabels:
      app: pelias-api
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: pelias-api
        app-group: pelias-api
      annotations:
        image: pelias/api:latest
    spec:
      initContainers:
        - name: init
          image: ghcr.io/headwaymaps/pelias-init:${HEADWAY_CONTAINER_VERSION}
          imagePullPolicy: Always
          volumeMounts:
            - name: config-volume
              mountPath: /config
          env:
            - name: PELIAS_CONFIG_JSON
              valueFrom:
                configMapKeyRef:
                  name: deployment-config
                  key: pelias-config-json
            - name: HEADWAY_AREA
              valueFrom:
                configMapKeyRef:
                  name: deployment-config
                  key: area
          command: ["/bin/bash", "-c", "/app/init_config.sh" ]
          resources:
            limits:
              memory: 200Mi
            requests:
              memory: 100Mi
      containers:
        - name: main
          image: pelias/api:latest
          ports:
            - containerPort: 4000
          volumeMounts:
            - name: config-volume
              mountPath: /config
          env:
            - name: PELIAS_CONFIG
              value: "/config/pelias.json"
            - name: PORT
              value: "4000"
          resources:
            limits:
              memory: 500Mi
            requests:
              memory: 100Mi
          livenessProbe:
            httpGet:
              path: /v1/
              port: 4000
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 10
          readinessProbe:
            httpGet:
              path: /v1/
              port: 4000
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 10
      volumes:
        - name: config-volume
          ephemeral:
            volumeClaimTemplate:
              spec:
                accessModes: [ "ReadWriteOnce" ]
                resources:
                  requests:
                    storage: 1Mi
