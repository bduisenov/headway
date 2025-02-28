apiVersion: apps/v1
kind: Deployment
metadata:
  name: opentripplanner
spec:
  selector:
    matchLabels:
      app: opentripplanner
  replicas: 1
  template:
    metadata:
      labels:
        app: opentripplanner
    spec:
      initContainers:
        - name: init
          image: ghcr.io/headwaymaps/opentripplanner-init:${HEADWAY_CONTAINER_VERSION}
          imagePullPolicy: Always
          volumeMounts:
            - name: opentripplanner-volume
              mountPath: /data
          env:
            - name: OTP_ARTIFACT_URL
              valueFrom:
                configMapKeyRef:
                  name: deployment-config
                  key: otp-graph-url
          resources:
            limits:
              memory: 128Mi
            requests:
              memory: 128Mi
      containers:
        - name: main
          image: ghcr.io/headwaymaps/opentripplanner:${HEADWAY_CONTAINER_VERSION}
          imagePullPolicy: Always
          ports:
            - containerPort: 8080
          volumeMounts:
            - name: opentripplanner-volume
              mountPath: /data
          resources:
            limits:
              memory: 4.5Gi
            requests:
              memory: 500Mi
          livenessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 15
            failureThreshold: 10
          readinessProbe:
            httpGet:
              path: /
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 15
            failureThreshold: 10
      volumes:
        - name: opentripplanner-volume
          ephemeral:
            volumeClaimTemplate:
              spec:
                accessModes: [ "ReadWriteOnce" ]
                resources:
                  requests:
                    storage: 1Gi
