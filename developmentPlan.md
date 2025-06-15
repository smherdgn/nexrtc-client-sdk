MOBILE UI FEATURES:
- Touch-friendly button sizes (minimum 44pt touch targets)
- Swipe gestures for camera switching and participant navigation
- Pinch-to-zoom for video streams
- Long press for additional options
- Haptic feedback for button interactions

ORIENTATION HANDLING:
- Portrait mode: Vertical video grid with controls at bottom
- Landscape mode: Horizontal video grid with floating controls
- Automatic rotation detection and layout adjustment
- Video aspect ratio optimization for orientation

PREVIOUS CODE: Build on useMobileWebRTC foundation from Phase 1
NEW FOCUS: Mobile UI components, touch interactions, responsive layout

Create intuitive mobile interface that feels native and responds well to touch interactions.
```

### **PROMPT 3: Native Features & Audio Management**
```
Add native mobile features, audio session management, and device integration.

TASK: Implement native audio management, proximity detection, and mobile-specific optimizations.

REQUIREMENTS:
1. Implement audio session management for iOS and Android
2. Add proximity sensor detection for automatic screen control
3. Create native camera management with torch and quality controls
4. Implement audio route switching (earpiece, speaker, bluetooth)
5. Add battery optimization and performance monitoring

NATIVE AUDIO FEATURES:
- iOS: AVAudioSession configuration for VoIP calls
- Android: AudioManager integration with focus handling
- Bluetooth audio device detection and switching
- Wired headset detection and automatic routing
- Call interruption handling (incoming phone calls)

PROXIMITY DETECTION:
- Automatic screen dimming when phone near ear
- Disable touch interactions during proximity
- Restore screen when phone moved away
- Prevent accidental button presses during calls

PREVIOUS CODE: Build on Phase 1 & 2 mobile components
NEW FOCUS: Native integration, audio management, device sensors

Integrate deeply with mobile platform capabilities for seamless native experience.
```

### **PROMPT 4: Performance Optimization & Production Polish**
```
Complete the mobile wrapper with performance optimizations and production-ready features.

TASK: Add performance monitoring, memory optimization, and comprehensive mobile testing.

REQUIREMENTS:
1. Implement battery usage optimization and monitoring
2. Add memory management for video streams and components
3. Create network adaptation for mobile data usage
4. Implement comprehensive testing for mobile-specific features
5. Add error handling for mobile edge cases and interruptions

PERFORMANCE OPTIMIZATIONS:
- Automatic video quality reduction on cellular networks
- Memory management for multiple video streams
- Battery usage monitoring and adaptive quality
- Background processing optimization
- GPU acceleration for video rendering

MOBILE EDGE CASES:
- Phone call interruptions and recovery
- Network switching (WiFi to cellular)
- Low memory situations and graceful degradation
- Device rotation during active calls
- App termination and state restoration

TESTING REQUIREMENTS:
- Unit tests for mobile hooks and utilities
- Integration tests with React Native Testing Library
- Device testing on iOS and Android simulators
- Performance benchmarks for battery and memory usage
- Network simulation testing for mobile conditions

PREVIOUS CODE: Complete mobile implementation from Phases 1-3
NEW FOCUS: Performance optimization, edge case handling, testing, production readiness

This should be a production-ready mobile library optimized for real-world mobile usage patterns.
```

---

# ⚙️ DEVELOPER 6: DevOps & Infrastructure

## 📋 **Complete Specification**

### **🎯 Your Mission**
Build the complete DevOps infrastructure for deploying, monitoring, and scaling the NexRTC SDK. You will create containerization, CI/CD pipelines, monitoring, and production deployment configurations.

### **📦 Deliverables**
```
@nextrtc/infrastructure/
├── docker/
│   ├── Dockerfile.dev           # Development container
│   ├── Dockerfile.prod          # Production container
│   ├── docker-compose.yml       # Local development setup
│   └── docker-compose.prod.yml  # Production deployment
├── kubernetes/
│   ├── namespace.yaml           # K8s namespace configuration
│   ├── deployment.yaml          # Application deployment
│   ├── service.yaml             # Service configuration
│   ├── ingress.yaml             # Ingress controller setup
│   ├── configmap.yaml           # Configuration management
│   ├── secrets.yaml             # Secret management
│   └── hpa.yaml                 # Horizontal Pod Autoscaler
├── ci-cd/
│   ├── .github/workflows/       # GitHub Actions workflows
│   ├── jenkins/                 # Jenkins pipeline configs
│   └── gitlab-ci.yml            # GitLab CI configuration
├── monitoring/
│   ├── prometheus/              # Metrics collection
│   ├── grafana/                 # Dashboards and visualization
│   ├── alertmanager/            # Alert management
│   └── loki/                    # Log aggregation
├── terraform/
│   ├── aws/                     # AWS infrastructure
│   ├── gcp/                     # Google Cloud infrastructure
│   ├── azure/                   # Azure infrastructure
│   └── modules/                 # Reusable Terraform modules
├── scripts/
│   ├── deploy.sh                # Deployment automation
│   ├── backup.sh                # Backup procedures
│   ├── health-check.sh          # Health monitoring
│   └── rollback.sh              # Rollback procedures
└── docs/
    ├── deployment-guide.md      # Deployment documentation
    ├── monitoring-setup.md      # Monitoring configuration
    └── troubleshooting.md       # Common issues and solutions
```

### **🔗 Integration Requirements**
```typescript
// YOU INTEGRATE: All other developer packages
import { NexRTCSDK } from '@nextrtc/core';
import { SecurityLayer } from '@nextrtc/security';
import { AnalyticsLayer } from '@nextrtc/analytics';
import { CallLayout } from '@nextrtc/ui-react';
import { MobileWrapper } from '@nextrtc/mobile';

// YOU PROVIDE: Production deployment and monitoring
export interface DeploymentConfig {
  environment: 'development' | 'staging' | 'production';
  replicas: number;
  resources: {
    requests: { cpu: string; memory: string };
    limits: { cpu: string; memory: string };
  };
  autoscaling: {
    enabled: boolean;
    minReplicas: number;
    maxReplicas: number;
    targetCPUUtilization: number;
  };
  monitoring: {
    enabled: boolean;
    metricsRetention: string;
    alerting: boolean;
  };
}

export interface MonitoringConfig {
  prometheus: {
    enabled: boolean;
    retention: string;
    scrapeInterval: string;
  };
  grafana: {
    enabled: boolean;
    dashboards: string[];
  };
  alerting: {
    channels: AlertChannel[];
    rules: AlertRule[];
  };
}

export interface AlertChannel {
  name: string;
  type: 'slack' | 'email' | 'pagerduty' | 'webhook';
  config: Record<string, any>;
}
```

### **🐳 Container Configuration**
```dockerfile
# Dockerfile.prod - Production container
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY packages/*/package.json ./packages/*/

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build all packages
RUN npm run build:all

# Production stage
FROM node:18-alpine AS runtime

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextrtc -u 1001

# Copy built application
COPY --from=builder --chown=nextrtc:nodejs /app/dist ./dist
COPY --from=builder --chown=nextrtc:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextrtc:nodejs /app/package.json ./

# Security hardening
RUN apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

USER nextrtc

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node dist/health-check.js

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/server.js"]
```

### **☸️ Kubernetes Deployment**
```yaml
# deployment.yaml - Kubernetes deployment configuration
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nextrtc-sdk
  namespace: nextrtc
  labels:
    app: nextrtc-sdk
    version: v2.0.0
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: nextrtc-sdk
  template:
    metadata:
      labels:
        app: nextrtc-sdk
        version: v2.0.0
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9090"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: nextrtc-service-account
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
      - name: nextrtc-sdk
        image: nextrtc/sdk:v2.0.0
        imagePullPolicy: Always
        ports:
        - containerPort: 3000
          name: http
        - containerPort: 9090
          name: metrics
        env:
        - name: NODE_ENV
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: nextrtc-secrets
              key: redis-url
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: nextrtc-secrets
              key: database-url
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        volumeMounts:
        - name: config
          mountPath: /app/config
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: nextrtc-config
```

### **📊 Monitoring Configuration**
```yaml
# prometheus-config.yaml - Prometheus monitoring setup
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: nextrtc
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    
    rule_files:
      - "/etc/prometheus/rules/*.yml"
    
    alerting:
      alertmanagers:
        - static_configs:
            - targets:
              - alertmanager:9093
    
    scrape_configs:
      - job_name: 'nextrtc-sdk'
        kubernetes_sd_configs:
          - role: pod
            namespaces:
              names:
                - nextrtc
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
        
      - job_name: 'nextrtc-business-metrics'
        scrape_interval: 30s
        static_configs:
          - targets: ['nextrtc-analytics:8080']
        metrics_path: /business-metrics
```

### **🚨 Alerting Rules**
```yaml
# alert-rules.yaml - Prometheus alerting rules
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: nextrtc-alerts
  namespace: nextrtc
spec:
  groups:
  - name: nextrtc.rules
    rules:
    # High error rate alert
    - alert: HighErrorRate
      expr: rate(nextrtc_errors_total[5m]) > 0.1
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value }} errors per second"
    
    # High CPU usage
    - alert: HighCPUUsage
      expr: rate(container_cpu_usage_seconds_total{pod=~"nextrtc-.*"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage on {{ $labels.pod }}"
        description: "CPU usage is {{ $value }}%"
    
    # Memory usage alert
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{pod=~"nextrtc-.*"} / container_spec_memory_limit_bytes > 0.9
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High memory usage on {{ $labels.pod }}"
        description: "Memory usage is {{ $value }}%"
    
    # Call success rate alert
    - alert: LowCallSuccessRate
      expr: rate(nextrtc_calls_successful_total[10m]) / rate(nextrtc_calls_total[10m]) < 0.95
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Low call success rate"
        description: "Call success rate is {{ $value }}%"
    
    # Business metric alerts
    - alert: HighCustomerChurn
      expr: nextrtc_churn_prediction_average > 0.3
      for: 15m
      labels:
        severity: warning
      annotations:
        summary: "High customer churn risk detected"
        description: "Average churn prediction is {{ $value }}"
```

### **🔄 CI/CD Pipeline**
```yaml
# .github/workflows/deploy.yml - GitHub Actions CI/CD
name: NexRTC SDK CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: nextrtc/sdk

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18, 20]
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
        cache: 'npm'
    
    - name: Install dependencies
      run: npm ci
    
    - name: Run linting
      run: npm run lint:all
    
    - name: Run tests
      run: npm run test:all
    
    - name: Run security audit
      run: npm audit --audit-level moderate
    
    - name: Build all packages
      run: npm run build:all

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v4
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha,prefix=sha-
          type=raw,value=latest,enable={{is_default_branch}}
    
    - name: Build and push Docker image
      id: build
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./docker/Dockerfile.prod
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}
        cache-from: type=gha
        cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v3
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG_STAGING }}
    
    - name: Deploy to staging
      run: |
        envsubst < kubernetes/deployment.yaml | kubectl apply -f -
        kubectl rollout status deployment/nextrtc-sdk -n nextrtc-staging
      env:
        IMAGE_TAG: ${{ needs.build.outputs.image-tag }}

  deploy-production:
    needs: [build, deploy-staging]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v3
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG_PRODUCTION }}
    
    - name: Deploy to production
      run: |
        envsubst < kubernetes/deployment.yaml | kubectl apply -f -
        kubectl rollout status deployment/nextrtc-sdk -n nextrtc-production
      env:
        IMAGE_TAG: ${{ needs.build.outputs.image-tag }}
    
    - name: Run smoke tests
      run: |
        ./scripts/smoke-tests.sh ${{ secrets.PRODUCTION_URL }}
```

---

## 🤖 **AI IMPLEMENTATION PROMPTS**

### **PROMPT 1: Containerization & Local Development**
```
I need you to build the DevOps infrastructure for a multi-package WebRTC SDK with containerization and local development setup.

TASK: Create Docker containers and local development environment for the NexRTC SDK.

REQUIREMENTS:
1. Create production-ready Dockerfile with multi-stage builds
2. Implement docker-compose setup for local development
3. Add health checks and security hardening for containers
4. Create development environment with hot reload
5. Set up volume mounts for development workflow

DOCKER REQUIREMENTS:
- Multi-stage build (builder + runtime stages)
- Non-root user for security
- Health checks for container monitoring
- Minimal attack surface (Alpine Linux base)
- Proper layer caching for faster builds

LOCAL DEVELOPMENT:
- docker-compose with all necessary services
- Volume mounts for live code editing
- Environment variable configuration
- Database and Redis containers for full stack
- Port mapping for development access

DELIVERABLES:
- Dockerfile.prod for production builds
- Dockerfile.dev for development
- docker-compose.yml for local development
- Health check scripts
- Container security configuration

Focus on container best practices and efficient development workflow. Don't implement orchestration yet.
```

### **PROMPT 2: Kubernetes Deployment & Orchestration**
```
Building on Phase 1, now implement Kubernetes deployment configurations and orchestration.

TASK: Add Kubernetes manifests for production deployment with auto-scaling and service management.

REQUIREMENTS:
1. Create Kubernetes deployment manifests with proper resource management
2. Implement service discovery and ingress configuration
3. Add horizontal pod autoscaling based on CPU and memory
4. Create ConfigMaps and Secrets for configuration management
5. Set up proper RBAC and security policies

KUBERNETES FEATURES:
- Rolling update deployment strategy
- Resource requests and limits
- Readiness and liveness probes
- Service accounts and RBAC
- Network policies for security

AUTO-SCALING CONFIGURATION:
- HPA based on CPU utilization (target 70%)
- Memory utilization monitoring
- Custom metrics scaling (call volume, error rate)
- Min 3 replicas, max 100 replicas
- Scale-down stabilization

PREVIOUS CODE: Build on Docker containers from Phase 1
NEW FOCUS: Kubernetes orchestration, scaling, service management

Create production-ready Kubernetes deployment that can handle enterprise scale.
```

### **PROMPT 3: CI/CD Pipeline & Automation**
```
Add comprehensive CI/CD pipeline with automated testing, security scanning, and deployment.

TASK: Implement GitHub Actions CI/CD pipeline with multi-environment deployment.

REQUIREMENTS:
1. Create comprehensive CI/CD pipeline with testing, building, and deployment
2. Add security scanning and vulnerability assessment
3. Implement multi-environment deployment (staging, production)
4. Add automated rollback capabilities and smoke testing
5. Create deployment automation scripts and health monitoring

CI/CD FEATURES:
- Multi-stage pipeline: test → security scan → build → deploy
- Parallel testing across Node.js versions
- Docker image building and registry push
- Automated deployment to Kubernetes
- Rollback mechanisms for failed deployments

SECURITY INTEGRATION:
- Dependency vulnerability scanning
- Container image security scanning
- SAST (Static Application Security Testing)
- License compliance checking
- Secrets management and rotation

PREVIOUS CODE: Build on Kubernetes configuration from Phase 2
NEW FOCUS: CI/CD automation, security scanning, deployment pipeline

Implement enterprise-grade CI/CD with comprehensive testing and security validation.
```

### **PROMPT 4: Monitoring, Alerting & Production Operations**
```
Complete the DevOps infrastructure with comprehensive monitoring, alerting, and production operations.

TASK: Implement Prometheus monitoring, Grafana dashboards, and complete production operations suite.

REQUIREMENTS:
1. Implement Prometheus metrics collection and Grafana dashboards
2. Create comprehensive alerting rules for technical and business metrics
3. Add log aggregation with structured logging
4. Implement backup, disaster recovery, and operational procedures
5. Create production troubleshooting guides and runbooks

MONITORING STACK:
- Prometheus for metrics collection
- Grafana for visualization and dashboards
- AlertManager for alert routing and management
- Loki for log aggregation
- Jaeger for distributed tracing

BUSINESS METRICS MONITORING:
- Call success rates and quality metrics
- Customer churn prediction alerts
- Revenue impact monitoring
- Performance SLA tracking
- User experience metrics

OPERATIONAL PROCEDURES:
- Automated backup procedures
- Disaster recovery testing
- Blue-green deployment scripts
- Database migration procedures
- Security incident response

PREVIOUS CODE: Complete infrastructure from Phases 1-3
NEW FOCUS: Monitoring, alerting, production operations, disaster recovery

This should be a complete production operations suite ready for enterprise deployment.
```

---

## 🎯 **Final Integration Notes**

### **📋 Integration Checklist**
Each developer must ensure their module:
- ✅ Implements exact TypeScript interfaces provided
- ✅ Subscribes to specified WebRTC core events
- ✅ Fires events at correct times with correct data
- ✅ Includes comprehensive error handling
- ✅ Provides complete test coverage
- ✅ Follows semantic versioning for breaking changes
- ✅ Includes proper documentation and examples

### **🔄 Assembly Process**
1. **Developer 1**: WebRTC core provides foundation events
2. **Developer 2**: Security subscribes to core events, adds protection
3. **Developer 3**: Analytics subscribes to core events, provides insights
4. **Developer 4**: React UI subscribes to core events, displays interface
5. **Developer 5**: Mobile wrapper extends core with mobile optimizations
6. **Developer 6**: DevOps packages everything for production deployment

### **🎯 Success Criteria**
- All packages install and build without errors
- Integration tests pass with mock implementations
- Real-world testing shows seamless module interaction
- Performance benchmarks meet enterprise requirements
- Security audits pass with zero critical issues
- Production deployment succeeds with monitoring active

**🚀 Result**: Complete enterprise WebRTC SDK ready for production use!OPTIMIZATION ALGORITHM:
- Analyze current bandwidth usage vs. available capacity
- Calculate optimal video resolution and bitrate settings
- Implement adaptive quality based on network conditions
- Generate cost savings estimates and quality impact assessments

BANDWIDTH OPTIMIZATION:
- Target 80% of available bandwidth (20% buffer)
- Progressive quality reduction: 1080p → 720p → 480p → audio-only
- Bitrate adaptation based on packet loss and RTT
- Automatic recovery when network improves

PREVIOUS CODE: Build on Phase 1 & 2 analytics infrastructure
NEW FOCUS: Performance optimization, bandwidth management, cost reduction

Create intelligent algorithms that balance quality with performance and cost efficiency.
```

### **PROMPT 4: Business Intelligence & Insights**
```
Complete the analytics engine with business intelligence and advanced insights generation.

TASK: Add business impact analysis and comprehensive analytics insights.

REQUIREMENTS:
1. Implement BusinessIntelligence class for revenue impact analysis
2. Add customer satisfaction correlation with technical metrics
3. Create executive dashboard data and insights generation
4. Implement comprehensive testing for all analytics algorithms
5. Add performance optimization and production readiness

BUSINESS INTELLIGENCE:
- Correlate call quality with customer satisfaction scores
- Calculate revenue impact of quality improvements
- Predict customer lifetime value based on usage patterns
- Generate executive insights and recommendations

INSIGHTS GENERATION:
- Weekly/monthly analytics reports
- Trend analysis and forecasting
- ROI calculations for infrastructure investments
- Customer segmentation and targeting recommendations

TESTING REQUIREMENTS:
- Unit tests for all prediction algorithms
- Integration tests with WebRTC core events
- Performance benchmarks for analytics processing
- Accuracy validation for prediction models

PREVIOUS CODE: Complete analytics implementation from Phases 1-3
NEW FOCUS: Business intelligence, insights generation, testing, production readiness

This module should provide actionable business insights and be ready for enterprise deployment.
```

---

# 🎨 DEVELOPER 4: React UI Components

## 📋 **Complete Specification**

### **🎯 Your Mission**
Build React UI components that provide a complete video calling interface. You will consume events from WebRTC core and display real-time call status, video streams, and controls.

### **📦 Deliverables**
```
@nextrtc/ui-react/
├── src/
│   ├── components/
│   │   ├── CallLayout.tsx        # Main call container
│   │   ├── VideoGrid.tsx         # Video stream display
│   │   ├── ControlBar.tsx        # Call controls
│   │   ├── QualityIndicator.tsx  # Network quality display
│   │   ├── ParticipantList.tsx   # Participant management
│   │   └── ErrorBoundary.tsx     # Error handling UI
│   ├── hooks/
│   │   ├── useWebRTCCall.ts      # Main call hook
│   │   ├── useMediaDevices.ts    # Device management
│   │   └── useCallQuality.ts     # Quality monitoring
│   ├── types/index.ts            # Component type definitions
│   └── index.ts                  # Package exports
├── dist/                         # Compiled output
├── package.json                 # NPM package config
└── README.md                    # Component documentation
```

### **🔗 Integration Contract (CONSUME WEBRTC EVENTS)**
```typescript
// YOU CONSUME: Events from @nextrtc/core
import { NexRTCCore, ConnectionHandle, CoreEvent, NetworkStats } from '@nextrtc/core';

// YOU PROVIDE: React components and hooks
export interface CallLayoutProps {
  core: NexRTCCore;
  roomId: string;
  userId: string;
  config?: UIConfig;
  onCallEnd?: () => void;
  onError?: (error: Error) => void;
}

export interface UIConfig {
  theme: 'light' | 'dark' | 'auto';
  showQualityIndicator: boolean;
  showParticipantCount: boolean;
  enableScreenShare: boolean;
  maxParticipantsDisplay: number;
  controlsPosition: 'bottom' | 'top' | 'floating';
}

export interface CallState {
  status: 'idle' | 'connecting' | 'connected' | 'disconnected' | 'error';
  participants: Participant[];
  localStream: MediaStream | null;
  remoteStreams: Map<string, MediaStream>;
  isVideoEnabled: boolean;
  isAudioEnabled: boolean;
  networkQuality: QualityLevel;
  error: Error | null;
}

export interface Participant {
  id: string;
  name?: string;
  isLocal: boolean;
  stream: MediaStream | null;
  isVideoEnabled: boolean;
  isAudioEnabled: boolean;
  qualityLevel: QualityLevel;
}

// Main hook that other components use
export interface UseWebRTCCallReturn {
  callState: CallState;
  actions: {
    joinCall: () => Promise<void>;
    leaveCall: () => Promise<void>;
    toggleVideo: () => Promise<void>;
    toggleAudio: () => Promise<void>;
    shareScreen: () => Promise<void>;
  };
  devices: {
    cameras: MediaDeviceInfo[];
    microphones: MediaDeviceInfo[];
    switchCamera: (deviceId: string) => Promise<void>;
    switchMicrophone: (deviceId: string) => Promise<void>;
  };
}
```

### **🎯 Core Component Implementation**
```typescript
// Main CallLayout component
export const CallLayout: React.FC<CallLayoutProps> = ({
  core,
  roomId,
  userId,
  config = {},
  onCallEnd,
  onError
}) => {
  const {
    callState,
    actions,
    devices
  } = useWebRTCCall({ core, roomId, userId });

  // Handle call errors
  useEffect(() => {
    if (callState.error && onError) {
      onError(callState.error);
    }
  }, [callState.error, onError]);

  return (
    <div className="nextrtc-call-layout" data-theme={config.theme}>
      {/* Video Grid - Shows all participants */}
      <VideoGrid
        participants={callState.participants}
        maxDisplay={config.maxParticipantsDisplay}
        localStream={callState.localStream}
        remoteStreams={callState.remoteStreams}
      />
      
      {/* Quality Indicator */}
      {config.showQualityIndicator && (
        <QualityIndicator
          level={callState.networkQuality}
          stats={callState.networkStats}
        />
      )}
      
      {/* Control Bar */}
      <ControlBar
        position={config.controlsPosition}
        isVideoEnabled={callState.isVideoEnabled}
        isAudioEnabled={callState.isAudioEnabled}
        onToggleVideo={actions.toggleVideo}
        onToggleAudio={actions.toggleAudio}
        onShareScreen={actions.shareScreen}
        onEndCall={() => {
          actions.leaveCall();
          onCallEnd?.();
        }}
        devices={devices}
      />
      
      {/* Participant List */}
      {config.showParticipantCount && (
        <ParticipantList participants={callState.participants} />
      )}
      
      {/* Connection Status */}
      <ConnectionStatus status={callState.status} />
    </div>
  );
};
```

### **🔗 useWebRTCCall Hook (CRITICAL INTEGRATION)**
```typescript
export const useWebRTCCall = ({ core, roomId, userId }: UseWebRTCCallParams): UseWebRTCCallReturn => {
  const [callState, setCallState] = useState<CallState>({
    status: 'idle',
    participants: [],
    localStream: null,
    remoteStreams: new Map(),
    isVideoEnabled: true,
    isAudioEnabled: true,
    networkQuality: 'good',
    error: null
  });

  const connectionRef = useRef<ConnectionHandle | null>(null);

  // CRITICAL: Subscribe to core events
  useEffect(() => {
    if (!core) return;

    const handleConnectionEstablished = (data: any) => {
      setCallState(prev => ({ ...prev, status: 'connected' }));
    };

    const handleParticipantJoined = (data: { participantId: string, stream: MediaStream }) => {
      setCallState(prev => ({
        ...prev,
        participants: [...prev.participants, {
          id: data.participantId,
          isLocal: false,
          stream: data.stream,
          isVideoEnabled: true,
          isAudioEnabled: true,
          qualityLevel: 'good'
        }],
        remoteStreams: new Map(prev.remoteStreams).set(data.participantId, data.stream)
      }));
    };

    const handleQualityChanged = (data: { quality: QualityLevel, stats: NetworkStats }) => {
      setCallState(prev => ({
        ...prev,
        networkQuality: data.quality,
        networkStats: data.stats
      }));
    };

    const handleError = (error: Error) => {
      setCallState(prev => ({ ...prev, error, status: 'error' }));
    };

    // Subscribe to all relevant events
    core.on('connection_established', handleConnectionEstablished);
    core.on('participant_joined', handleParticipantJoined);
    core.on('participant_left', handleParticipantLeft);
    core.on('media_stream_added', handleMediaStreamAdded);
    core.on('quality_changed', handleQualityChanged);
    core.on('error_occurred', handleError);

    return () => {
      // Cleanup subscriptions
      core.off('connection_established', handleConnectionEstablished);
      core.off('participant_joined', handleParticipantJoined);
      // ... cleanup all subscriptions
    };
  }, [core]);

  // Call actions
  const joinCall = useCallback(async () => {
    try {
      setCallState(prev => ({ ...prev, status: 'connecting' }));
      const connection = await core.createConnection(roomId);
      connectionRef.current = connection;
      await core.joinRoom(connection);
    } catch (error) {
      setCallState(prev => ({ ...prev, error: error as Error, status: 'error' }));
    }
  }, [core, roomId]);

  const leaveCall = useCallback(async () => {
    if (connectionRef.current) {
      await core.leaveRoom(connectionRef.current);
      setCallState(prev => ({ ...prev, status: 'disconnected' }));
    }
  }, [core]);

  const toggleVideo = useCallback(async () => {
    if (connectionRef.current) {
      await core.toggleVideo(connectionRef.current);
      setCallState(prev => ({ ...prev, isVideoEnabled: !prev.isVideoEnabled }));
    }
  }, [core]);

  return {
    callState,
    actions: { joinCall, leaveCall, toggleVideo, toggleAudio, shareScreen },
    devices: { cameras, microphones, switchCamera, switchMicrophone }
  };
};
```

### **🎨 Component Requirements**

**VideoGrid Component:**
```typescript
export const VideoGrid: React.FC<VideoGridProps> = ({
  participants,
  localStream,
  remoteStreams,
  maxDisplay = 9
}) => {
  const displayParticipants = participants.slice(0, maxDisplay);
  
  return (
    <div className="nextrtc-video-grid" data-participant-count={displayParticipants.length}>
      {/* Local video */}
      {localStream && (
        <VideoTile
          stream={localStream}
          isLocal={true}
          participantName="You"
          isVideoEnabled={true}
        />
      )}
      
      {/* Remote videos */}
      {displayParticipants.map(participant => (
        <VideoTile
          key={participant.id}
          stream={participant.stream}
          isLocal={false}
          participantName={participant.name}
          isVideoEnabled={participant.isVideoEnabled}
          qualityLevel={participant.qualityLevel}
        />
      ))}
    </div>
  );
};
```

**ControlBar Component:**
```typescript
export const ControlBar: React.FC<ControlBarProps> = ({
  isVideoEnabled,
  isAudioEnabled,
  onToggleVideo,
  onToggleAudio,
  onShareScreen,
  onEndCall,
  devices
}) => {
  return (
    <div className="nextrtc-control-bar">
      <Button
        onClick={onToggleVideo}
        variant={isVideoEnabled ? 'primary' : 'secondary'}
        icon={isVideoEnabled ? 'camera-on' : 'camera-off'}
      >
        {isVideoEnabled ? 'Camera On' : 'Camera Off'}
      </Button>
      
      <Button
        onClick={onToggleAudio}
        variant={isAudioEnabled ? 'primary' : 'secondary'}
        icon={isAudioEnabled ? 'mic-on' : 'mic-off'}
      >
        {isAudioEnabled ? 'Mic On' : 'Mic Off'}
      </Button>
      
      <Button onClick={onShareScreen} icon="screen-share">
        Share Screen
      </Button>
      
      <DeviceSelector devices={devices} />
      
      <Button onClick={onEndCall} variant="danger" icon="phone-off">
        End Call
      </Button>
    </div>
  );
};
```

---

## 🤖 **AI IMPLEMENTATION PROMPTS**

### **PROMPT 1: React Foundation & Core Hook**
```
I need you to build React UI components for a WebRTC video calling interface.

TASK: Create the foundation with the main useWebRTCCall hook and basic components.

REQUIREMENTS:
1. Create React TypeScript project with proper component structure
2. Implement useWebRTCCall hook that integrates with WebRTC core events
3. Create basic CallLayout component as main container
4. Implement event subscription pattern for real-time updates
5. Add proper state management for call status and participants

INTEGRATION PATTERN:
The React components consume WebRTC core events and update UI accordingly:
- 'connection_established' → Update call status to connected
- 'participant_joined' → Add participant to UI
- 'media_stream_added' → Display video streams
- 'quality_changed' → Update quality indicators

INTERFACES TO IMPLEMENT:
[Include CallLayoutProps and UseWebRTCCallReturn from above]

DELIVERABLES:
- useWebRTCCall hook with event subscription
- CallLayout component with basic structure
- CallState management and updates
- TypeScript types and interfaces
- Integration with @nextrtc/core package

Focus on the hook foundation and basic layout. Don't implement detailed UI components yet.
```

### **PROMPT 2: Video Components & Stream Handling**
```
Building on Phase 1, now implement video display components and stream management.

TASK: Add VideoGrid, VideoTile components and media stream handling.

REQUIREMENTS:
1. Implement VideoGrid component for displaying multiple video streams
2. Create VideoTile component for individual participant videos
3. Add proper video element management and stream attachment
4. Implement responsive grid layout for different participant counts
5. Add local vs remote video handling with proper mirroring

VIDEO DISPLAY FEATURES:
- Responsive grid layout (1, 2, 4, 6, 9 participants)
- Local video mirroring and positioning
- Remote video stream attachment and cleanup
- Video placeholder when camera disabled
- Participant name overlays and status indicators

STREAM MANAGEMENT:
- Automatic stream attachment to video elements
- Proper cleanup on participant leave
- Handle stream track enable/disable
- Audio visualization for audio-only participants

PREVIOUS CODE: Build on useWebRTCCall hook from Phase 1
NEW FOCUS: Video components, stream handling, responsive layout

Ensure smooth video playback and proper resource management for multiple streams.
```

### **PROMPT 3: Controls & Device Management**
```
Add control bar, device selection, and interaction components.

TASK: Implement ControlBar, device management, and user interaction controls.

REQUIREMENTS:
1. Implement ControlBar component with video/audio toggle buttons
2. Add DeviceSelector for camera and microphone switching
3. Create QualityIndicator component for network status display
4. Implement ParticipantList component for participant management
5. Add proper button states and loading indicators

CONTROL FEATURES:
- Video/audio toggle with visual feedback
- Device selection dropdowns with real-time switching
- Screen sharing button and handling
- End call functionality with confirmation
- Keyboard shortcuts for common actions

DEVICE MANAGEMENT:
- Enumerate available cameras and microphones
- Real-time device switching without call interruption
- Device permission handling and error states
- Default device selection and preferences

PREVIOUS CODE: Build on Phase 1 & 2 video components
NEW FOCUS: User controls, device management, interaction

Create intuitive controls that provide immediate feedback and handle edge cases gracefully.
```

### **PROMPT 4: Polish, Accessibility & Testing**
```
Complete the React components with accessibility, theming, and comprehensive testing.

TASK: Add accessibility features, responsive design, and production-ready polish.

REQUIREMENTS:
1. Implement full accessibility support (ARIA labels, keyboard navigation)
2. Add responsive design for mobile and desktop
3. Create theming system with light/dark modes
4. Implement comprehensive test suite for all components
5. Add error boundaries and graceful error handling

ACCESSIBILITY FEATURES:
- ARIA labels for all interactive elements
- Keyboard navigation for all controls
- Screen reader announcements for call events
- Focus management during state changes
- High contrast mode support

RESPONSIVE DESIGN:
- Mobile-first responsive layout
- Touch-friendly controls on mobile
- Proper video scaling on different screen sizes
- Adaptive control positioning

TESTING REQUIREMENTS:
- Unit tests for all components using React Testing Library
- Integration tests with WebRTC core mocks
- Accessibility testing with axe-core
- Visual regression tests for UI consistency

PREVIOUS CODE: Complete React implementation from Phases 1-3
NEW FOCUS: Accessibility, responsive design, testing, production readiness

This should be a production-ready component library with enterprise-grade accessibility and testing.
```

---

# 📱 DEVELOPER 5: React Native Mobile Wrapper

## 📋 **Complete Specification**

### **🎯 Your Mission**
Build React Native components and platform wrappers that provide native mobile optimization for iOS and Android. You will integrate WebRTC core with mobile-specific features and lifecycle management.

### **📦 Deliverables**
```
@nextrtc/mobile/
├── src/
│   ├── components/
│   │   ├── MobileCallLayout.tsx     # Mobile-optimized call layout
│   │   ├── MobileVideoGrid.tsx      # Touch-friendly video grid
│   │   ├── MobileControlBar.tsx     # Mobile control interface
│   │   └── NativeCallScreen.tsx     # Full-screen call interface
│   ├── hooks/
│   │   ├── useMobileWebRTC.ts       # Mobile-specific call hook
│   │   ├── useAppStateManager.ts    # Background/foreground handling
│   │   ├── useDeviceOrientation.ts  # Orientation management
│   │   └── useAudioSession.ts       # Audio session management
│   ├── native/
│   │   ├── ios/                     # iOS-specific implementations
│   │   ├── android/                 # Android-specific implementations
│   │   └── bridge/                  # Native bridge modules
│   ├── utils/
│   │   ├── permissions.ts           # Mobile permission handling
│   │   ├── lifecycle.ts             # App lifecycle management
│   │   └── optimization.ts          # Mobile performance optimization
│   └── types/index.ts               # Mobile type definitions
├── dist/                            # Compiled output
├── package.json                    # NPM package config
└── README.md                       # Mobile integration docs
```

### **🔗 Integration Contract (MOBILE-SPECIFIC FEATURES)**
```typescript
// YOU CONSUME: Events from @nextrtc/core
import { NexRTCCore, ConnectionHandle, CoreEvent } from '@nextrtc/core';

// YOU PROVIDE: Mobile-optimized components and native integration
export interface MobileCallLayoutProps {
  core: NexRTCCore;
  roomId: string;
  userId: string;
  config?: MobileUIConfig;
  onCallEnd?: () => void;
  onBackground?: () => void;
  onForeground?: () => void;
}

export interface MobileUIConfig {
  orientation: 'portrait' | 'landscape' | 'auto';
  enableBackgroundMode: boolean;
  enableProximityDetection: boolean;
  audioSessionMode: 'voice' | 'video' | 'auto';
  batteryOptimization: boolean;
  fullScreenMode: boolean;
}

export interface MobileCallState extends CallState {
  appState: AppStateStatus;
  orientation: OrientationStatus;
  batteryLevel: number;
  isInBackground: boolean;
  audioRoute: AudioRoute;
  proximityState: boolean;
}

export type AppStateStatus = 'active' | 'background' | 'inactive';
export type OrientationStatus = 'portrait' | 'landscape' | 'unknown';
export type AudioRoute = 'earpiece' | 'speaker' | 'bluetooth' | 'wired';

export interface UseMobileWebRTCReturn {
  callState: MobileCallState;
  actions: {
    joinCall: () => Promise<void>;
    leaveCall: () => Promise<void>;
    toggleVideo: () => Promise<void>;
    toggleAudio: () => Promise<void>;
    switchCamera: () => Promise<void>;
    enableSpeaker: (enabled: boolean) => Promise<void>;
  };
  permissions: {
    requestCameraPermission: () => Promise<boolean>;
    requestMicrophonePermission: () => Promise<boolean>;
    checkPermissions: () => Promise<PermissionStatus>;
  };
  lifecycle: {
    handleAppStateChange: (state: AppStateStatus) => void;
    handleOrientationChange: (orientation: OrientationStatus) => void;
    optimizeForBattery: (enabled: boolean) => void;
  };
}
```

### **🎯 Mobile-Specific Integration**
```typescript
export class MobileWrapper {
  private core: NexRTCCore;
  private appStateSubscription: any;
  private orientationSubscription: any;
  private proximityListener: any;

  constructor(core: NexRTCCore) {
    this.core = core;
    this.setupMobileIntegration();
  }

  private setupMobileIntegration() {
    // CRITICAL: Subscribe to core events for mobile optimization
    this.core.on('connection_established', this.handleConnectionEstablished.bind(this));
    this.core.on('participant_joined', this.optimizeForParticipants.bind(this));
    this.core.on('quality_changed', this.handleQualityChange.bind(this));
    this.core.on('error_occurred', this.handleMobileError.bind(this));

    // Mobile lifecycle integration
    this.setupAppStateHandling();
    this.setupOrientationHandling();
    this.setupAudioSessionManagement();
    this.setupProximityDetection();
  }

  private setupAppStateHandling() {
    import('react-native').then(({ AppState }) => {
      this.appStateSubscription = AppState.addEventListener('change', (nextAppState) => {
        if (nextAppState === 'background') {
          this.handleAppBackground();
        } else if (nextAppState === 'active') {
          this.handleAppForeground();
        }
      });
    });
  }

  private async handleAppBackground() {
    // Optimize for background mode
    // Disable video to save battery
    // Maintain audio connection
    // Reduce quality to minimum viable
    await this.core.toggleVideo(this.currentConnection); // Disable video
    this.optimizeForBackground();
  }

  private async handleAppForeground() {
    // Restore from background
    // Re-enable video if was enabled
    // Restore quality settings
    // Resume normal operation
    this.restoreFromBackground();
  }
}
```

### **📱 Mobile Components Implementation**
```typescript
// Mobile-optimized call layout
export const MobileCallLayout: React.FC<MobileCallLayoutProps> = ({
  core,
  roomId,
  userId,
  config = {},
  onCallEnd,
  onBackground,
  onForeground
}) => {
  const {
    callState,
    actions,
    permissions,
    lifecycle
  } = useMobileWebRTC({ core, roomId, userId });

  const [orientation, setOrientation] = useState<OrientationStatus>('portrait');

  // Handle orientation changes
  useEffect(() => {
    const subscription = Orientation.addOrientationListener((orientation) => {
      setOrientation(orientation);
      lifecycle.handleOrientationChange(orientation);
    });

    return () => subscription?.remove();
  }, []);

  // Handle app state changes
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (nextAppState) => {
      lifecycle.handleAppStateChange(nextAppState);
      
      if (nextAppState === 'background') {
        onBackground?.();
      } else if (nextAppState === 'active') {
        onForeground?.();
      }
    });

    return () => subscription?.remove();
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      {config.fullScreenMode ? (
        <NativeCallScreen
          callState={callState}
          actions={actions}
          orientation={orientation}
          onEndCall={onCallEnd}
        />
      ) : (
        <View style={styles.normalLayout}>
          <MobileVideoGrid
            participants={callState.participants}
            localStream={callState.localStream}
            remoteStreams={callState.remoteStreams}
            orientation={orientation}
          />
          
          <MobileControlBar
            isVideoEnabled={callState.isVideoEnabled}
            isAudioEnabled={callState.isAudioEnabled}
            onToggleVideo={actions.toggleVideo}
            onToggleAudio={actions.toggleAudio}
            onSwitchCamera={actions.switchCamera}
            onToggleSpeaker={actions.enableSpeaker}
            onEndCall={onCallEnd}
          />
        </View>
      )}
      
      {/* Mobile-specific overlays */}
      <ConnectionStatusOverlay status={callState.status} />
      <QualityIndicatorOverlay quality={callState.networkQuality} />
      {callState.isInBackground && <BackgroundModeIndicator />}
    </SafeAreaView>
  );
};
```

### **🔧 Mobile Optimization Features**
```typescript
export const useMobileWebRTC = ({ core, roomId, userId }: UseMobileWebRTCParams): UseMobileWebRTCReturn => {
  const [callState, setCallState] = useState<MobileCallState>({
    ...defaultCallState,
    appState: 'active',
    orientation: 'portrait',
    batteryLevel: 100,
    isInBackground: false,
    audioRoute: 'earpiece',
    proximityState: false
  });

  // Battery optimization
  const optimizeForBattery = useCallback((enabled: boolean) => {
    if (enabled) {
      // Reduce video quality
      // Lower frame rate
      // Disable non-essential features
      setCallState(prev => ({ ...prev, batteryOptimization: true }));
    }
  }, []);

  // Audio session management
  const setupAudioSession = useCallback(async () => {
    try {
      // Configure audio session for VoIP
      await AudioSessionManager.setCategory('playAndRecord');
      await AudioSessionManager.setMode('voiceChat');
      await AudioSessionManager.setActive(true);
    } catch (error) {
      console.warn('Audio session setup failed:', error);
    }
  }, []);

  // Camera switching (front/back)
  const switchCamera = useCallback(async () => {
    try {
      // Switch between front and back camera
      await CameraManager.switchCamera();
      setCallState(prev => ({ ...prev, cameraPosition: prev.cameraPosition === 'front' ? 'back' : 'front' }));
    } catch (error) {
      console.warn('Camera switch failed:', error);
    }
  }, []);

  // Permission handling
  const requestCameraPermission = useCallback(async (): Promise<boolean> => {
    try {
      const permission = await PermissionsAndroid.request(
        PermissionsAndroid.PERMISSIONS.CAMERA
      );
      return permission === PermissionsAndroid.RESULTS.GRANTED;
    } catch (error) {
      return false;
    }
  }, []);

  return {
    callState,
    actions: {
      joinCall,
      leaveCall,
      toggleVideo,
      toggleAudio,
      switchCamera,
      enableSpeaker
    },
    permissions: {
      requestCameraPermission,
      requestMicrophonePermission,
      checkPermissions
    },
    lifecycle: {
      handleAppStateChange,
      handleOrientationChange,
      optimizeForBattery
    }
  };
};
```

### **📲 Native Bridge Modules**
```typescript
// iOS-specific implementations
export interface IOSAudioSession {
  setCategory(category: string): Promise<void>;
  setMode(mode: string): Promise<void>;
  configureForVoIP(): Promise<void>;
  handleInterruption(): Promise<void>;
}

// Android-specific implementations  
export interface AndroidAudioManager {
  setAudioMode(mode: number): Promise<void>;
  setSpeakerphoneOn(enabled: boolean): Promise<void>;
  requestAudioFocus(): Promise<void>;
  abandonAudioFocus(): Promise<void>;
}

// Cross-platform camera management
export interface CameraManager {
  switchCamera(): Promise<void>;
  getCameraPosition(): Promise<'front' | 'back'>;
  enableTorch(enabled: boolean): Promise<void>;
  setVideoQuality(quality: VideoQuality): Promise<void>;
}
```

---

## 🤖 **AI IMPLEMENTATION PROMPTS**

### **PROMPT 1: Mobile Foundation & App Lifecycle**
```
I need you to build React Native components for mobile WebRTC video calling with platform-specific optimizations.

TASK: Create the mobile foundation with app lifecycle management and basic mobile integration.

REQUIREMENTS:
1. Create React Native TypeScript project with proper mobile component structure
2. Implement useMobileWebRTC hook that extends web WebRTC with mobile features
3. Add AppState handling for background/foreground transitions
4. Create basic MobileCallLayout component with SafeAreaView
5. Implement mobile permission handling for camera and microphone

MOBILE-SPECIFIC FEATURES:
- AppState.addEventListener for background/foreground handling
- PermissionsAndroid for Android permission requests
- iOS permission handling through native modules
- Battery optimization when app goes to background
- Audio session configuration for VoIP calls

INTEGRATION PATTERN:
Extend WebRTC core with mobile lifecycle:
- App goes to background → Disable video, maintain audio
- App returns to foreground → Restore video if was enabled
- Handle phone calls and interruptions gracefully

INTERFACES TO IMPLEMENT:
[Include MobileCallLayoutProps and UseMobileWebRTCReturn from above]

DELIVERABLES:
- useMobileWebRTC hook with app lifecycle handling
- MobileCallLayout component with mobile optimizations
- Permission handling utilities
- Mobile state management
- Integration with @nextrtc/core package

Focus on mobile lifecycle and permission foundation. Don't implement detailed UI components yet.
```

### **PROMPT 2: Mobile UI Components & Touch Interface**
```
Building on Phase 1, now implement mobile-optimized UI components with touch interactions.

TASK: Add mobile video components and touch-friendly control interface.

REQUIREMENTS:
1. Implement MobileVideoGrid with touch gestures and responsive layout
2. Create MobileControlBar with large touch targets and mobile-specific controls
3. Add camera switching functionality (front/back camera)
4. Implement orientation handling and responsive video layout
5. Add speaker toggle and audio route management

MOBILE UI FEATURES:
- Touch-friendly button sizes (minimum 44pt touch targets)
- Swipe gestures for# 🚀 NexRTC SDK - Complete Developer Implementation Briefs

> **Plug-and-Play Development**: Each developer gets complete specifications + 4-phase AI prompts for progressive implementation.

---

# 👨‍💻 DEVELOPER 1: WebRTC Core Engine

## 📋 **Complete Specification**

### **🎯 Your Mission**
Build the core WebRTC engine that handles peer connections, signaling, and media management. This is the foundation that all other modules will integrate with.

### **📦 Deliverables**
```
@nextrtc/core/
├── src/
│   ├── WebRTCEngine.ts      # Main engine class
│   ├── SignalingClient.ts   # WebSocket signaling
│   ├── MediaManager.ts      # Camera/mic handling
│   ├── ConnectionManager.ts # Peer connection logic
│   └── types/index.ts       # TypeScript definitions
├── dist/                    # Compiled output
├── package.json            # NPM package config
└── README.md               # Usage documentation
```

### **🔗 Exact API Contract (NEVER CHANGE THESE)**
```typescript
// MASTER INTERFACE - This is sacred!
export interface NexRTCCore {
  initialize(config: CoreConfig): Promise<void>;
  createConnection(roomId: string): Promise<ConnectionHandle>;
  joinRoom(handle: ConnectionHandle): Promise<void>;
  leaveRoom(handle: ConnectionHandle): Promise<void>;
  toggleVideo(handle: ConnectionHandle): Promise<void>;
  toggleAudio(handle: ConnectionHandle): Promise<void>;
  getStats(handle: ConnectionHandle): Promise<RTCStatsReport>;
  destroy(): Promise<void>;
}

export interface ConnectionHandle {
  readonly id: string;
  readonly roomId: string;
  readonly state: ConnectionState;
  readonly localStream: MediaStream | null;
  readonly remoteStreams: Map<string, MediaStream>;
  on(event: CoreEvent, callback: EventCallback): void;
  off(event: CoreEvent, callback: EventCallback): void;
}

export type CoreEvent = 
  | 'connection_established'
  | 'connection_failed'
  | 'connection_closed'
  | 'participant_joined'
  | 'participant_left'
  | 'media_stream_added'
  | 'media_stream_removed'
  | 'quality_changed'
  | 'network_stats_updated'
  | 'error_occurred';

export type ConnectionState = 'idle' | 'connecting' | 'connected' | 'disconnected' | 'failed';

export interface CoreConfig {
  signaling: {
    url: string;
    token?: string;
    reconnectAttempts?: number;
  };
  iceServers: RTCIceServer[];
  media: {
    video: boolean | MediaTrackConstraints;
    audio: boolean | MediaTrackConstraints;
  };
  debug?: boolean;
}

export interface NetworkStats {
  rtt: number;
  jitter: number;
  packetLoss: number;
  bandwidth: number;
  timestamp: number;
}

type EventCallback = (data: any) => void;
```

### **🎯 Implementation Requirements**

**WebRTCEngine Class:**
```typescript
export class WebRTCEngine implements NexRTCCore {
  private connections = new Map<string, ConnectionHandle>();
  private config: CoreConfig;
  private signalingClient: SignalingClient;
  private mediaManager: MediaManager;
  
  constructor() {
    // Initialize components
  }
  
  async initialize(config: CoreConfig): Promise<void> {
    // Setup signaling connection
    // Initialize media devices
    // Configure ICE servers
  }
  
  async createConnection(roomId: string): Promise<ConnectionHandle> {
    // Create RTCPeerConnection
    // Setup media streams
    // Return connection handle
  }
  
  // CRITICAL: Must fire these exact events at right times
  private fireEvent(connectionId: string, event: CoreEvent, data: any) {
    // Other modules depend on these events!
    // 'participant_joined' → Security module validates
    // 'quality_changed' → Analytics module analyzes
    // 'network_stats_updated' → Performance tracking
  }
}
```

**Event Firing Requirements (CRITICAL):**
- `connection_established` → When WebRTC connection succeeds
- `participant_joined` → When remote peer joins (includes participant info)
- `quality_changed` → When network quality changes (includes NetworkStats)
- `network_stats_updated` → Every 2 seconds with current stats
- `error_occurred` → Any error with error details

### **📈 Performance Requirements**
- Connection establishment: <3 seconds
- Event firing latency: <50ms
- Memory usage: <100MB per connection
- Support: 10+ concurrent connections

### **🧪 Testing Requirements**
```typescript
// Your tests must prove these work
describe('WebRTCEngine', () => {
  test('fires connection_established event', async () => {
    // Mock successful connection
    // Verify event fired with correct data
  });
  
  test('provides accurate network stats', async () => {
    // Mock RTCStatsReport
    // Verify NetworkStats calculation
  });
  
  test('handles signaling reconnection', async () => {
    // Mock connection drop
    // Verify automatic reconnection
  });
});
```

---

## 🤖 **AI IMPLEMENTATION PROMPTS**

### **PROMPT 1: Foundation & Setup**
```
I need you to implement the foundation of a WebRTC engine for a production SDK. 

TASK: Create the basic project structure and core classes.

REQUIREMENTS:
1. Create a TypeScript project with proper package.json
2. Implement the base WebRTCEngine class that implements the NexRTCCore interface
3. Create a basic SignalingClient class for WebSocket communication
4. Set up proper TypeScript types and exports
5. Include basic error handling and logging

INTERFACE TO IMPLEMENT:
[Include the NexRTCCore interface from above]

DELIVERABLES:
- Complete project structure
- WebRTCEngine class skeleton with all required methods
- SignalingClient class with connect/disconnect/send methods
- Proper TypeScript configuration
- Basic package.json with dependencies

Focus on clean architecture and proper TypeScript typing. Don't implement WebRTC logic yet, just the foundation.
```

### **PROMPT 2: WebRTC Connection Logic**
```
Building on the foundation from Phase 1, now implement the core WebRTC functionality.

TASK: Add RTCPeerConnection management and media handling.

REQUIREMENTS:
1. Implement createConnection() method with full RTCPeerConnection setup
2. Add ICE candidate handling and SDP offer/answer exchange
3. Implement media stream management (getUserMedia, track handling)
4. Add connection state management and event firing
5. Implement the ConnectionHandle class with proper event emitter

CRITICAL EVENT FIRING:
- Fire 'connection_established' when RTCPeerConnection state becomes 'connected'
- Fire 'participant_joined' when remote streams are added
- Fire 'media_stream_added' when tracks are received
- Fire 'error_occurred' for any WebRTC errors

PREVIOUS CODE: Use the foundation classes from Phase 1
NEW FOCUS: WebRTC peer connection logic, media handling, state management

The connection flow should be: initialize() → createConnection() → joinRoom() → automatic WebRTC handshake
```

### **PROMPT 3: Advanced Features & Optimization**
```
Enhance the WebRTC engine with advanced features and network monitoring.

TASK: Add network quality monitoring, stats collection, and optimization features.

REQUIREMENTS:
1. Implement getStats() method with RTCStatsReport processing
2. Add NetworkStats calculation (RTT, jitter, packet loss, bandwidth)
3. Implement automatic quality monitoring with 'network_stats_updated' events
4. Add reconnection logic for both signaling and peer connections
5. Implement toggleVideo() and toggleAudio() methods
6. Add proper cleanup in destroy() method

NETWORK STATS PARSING:
- Extract RTT from candidate-pair stats
- Calculate packet loss from inbound-rtp stats  
- Parse jitter from audio/video track stats
- Fire 'quality_changed' when metrics cross thresholds

PREVIOUS CODE: Build on Phase 1 & 2 implementation
NEW FOCUS: Performance monitoring, stats collection, media controls
```

### **PROMPT 4: Production Polish & Testing**
```
Finalize the WebRTC engine with production-ready features and comprehensive testing.

TASK: Add error handling, edge cases, and comprehensive test suite.

REQUIREMENTS:
1. Robust error handling for all WebRTC failure scenarios
2. Implement connection recovery and failover logic
3. Add comprehensive logging and debug mode support
4. Create complete test suite covering all public methods
5. Add proper JSDoc documentation for all public APIs
6. Optimize performance and memory usage

ERROR SCENARIOS TO HANDLE:
- ICE connection failures with fallback to TURN
- Signaling disconnections with exponential backoff reconnection
- Media device access denied with graceful degradation
- Network changes and reconnection handling

TESTING REQUIREMENTS:
- Unit tests for all public methods
- Integration tests for WebRTC flows
- Mock implementations for browser APIs
- Performance benchmarks

PREVIOUS CODE: Complete implementation from Phases 1-3
NEW FOCUS: Production readiness, error handling, testing, documentation

This is the final phase - the module should be ready for integration with other SDK components.
```

---

# 🔐 DEVELOPER 2: Security & Compliance Engine

## 📋 **Complete Specification**

### **🎯 Your Mission**
Build the security layer that provides end-to-end encryption, authentication, and compliance features. You will consume events from the WebRTC core and add security on top.

### **📦 Deliverables**
```
@nextrtc/security/
├── src/
│   ├── SecurityManager.ts    # Main security orchestrator
│   ├── EncryptionEngine.ts   # E2E encryption logic
│   ├── AuthProvider.ts       # Authentication handling
│   ├── ComplianceManager.ts  # GDPR/HIPAA compliance
│   ├── AuditLogger.ts        # Security event logging
│   └── types/index.ts        # Security type definitions
├── dist/                     # Compiled output
├── package.json             # NPM package config
└── README.md                # Security documentation
```

### **🔗 Integration Contract (CONSUME THESE EVENTS)**
```typescript
// YOU CONSUME: Events from @nextrtc/core
import { NexRTCCore, CoreEvent, ConnectionHandle } from '@nextrtc/core';

// YOU PROVIDE: Security services to other modules
export interface SecurityLayer {
  initialize(core: NexRTCCore, config: SecurityConfig): Promise<void>;
  encryptMessage(roomId: string, message: any): Promise<EncryptedData>;
  decryptMessage(roomId: string, encrypted: EncryptedData): Promise<any>;
  validateParticipant(participantId: string, token: string): Promise<ValidationResult>;
  logSecurityEvent(event: SecurityEvent): void;
  checkCompliance(data: any, framework: ComplianceFramework): ComplianceResult;
  generateAuditReport(timeRange: TimeRange): Promise<AuditReport>;
}

export interface SecurityConfig {
  encryption: {
    enabled: boolean;
    algorithm: 'AES-256-GCM' | 'ChaCha20-Poly1305';
    keyRotationInterval: number; // seconds
  };
  authentication: {
    provider: 'jwt' | 'oauth' | 'custom';
    issuer?: string;
    audience?: string;
  };
  compliance: {
    frameworks: ComplianceFramework[];
    auditLevel: 'basic' | 'detailed' | 'comprehensive';
    dataRetention: number; // days
  };
  debug?: boolean;
}

export type ComplianceFramework = 'gdpr' | 'hipaa' | 'ccpa' | 'sox';

export interface EncryptedData {
  algorithm: string;
  iv: string;
  data: string;
  authTag: string;
  timestamp: number;
}

export interface ValidationResult {
  isValid: boolean;
  userId?: string;
  permissions: string[];
  expiresAt?: number;
  reason?: string;
}

export interface SecurityEvent {
  type: SecurityEventType;
  timestamp: number;
  userId?: string;
  roomId?: string;
  details: Record<string, any>;
  severity: 'low' | 'medium' | 'high' | 'critical';
}

export type SecurityEventType =
  | 'authentication_success'
  | 'authentication_failure'
  | 'encryption_key_generated'
  | 'encryption_key_rotated'
  | 'unauthorized_access_attempt'
  | 'compliance_violation'
  | 'audit_log_access';
```

### **🎯 Core Event Integration (CRITICAL)**
```typescript
export class SecurityManager implements SecurityLayer {
  private core: NexRTCCore;
  private encryptionEngine: EncryptionEngine;
  private auditLogger: AuditLogger;
  
  async initialize(core: NexRTCCore, config: SecurityConfig): Promise<void> {
    this.core = core;
    
    // CRITICAL: Subscribe to core events for security monitoring
    this.core.on('connection_established', this.handleSecureConnection.bind(this));
    this.core.on('participant_joined', this.validateNewParticipant.bind(this));
    this.core.on('participant_left', this.handleParticipantLeft.bind(this));
    this.core.on('error_occurred', this.handleSecurityError.bind(this));
  }
  
  private async handleSecureConnection(data: { connectionId: string, roomId: string }) {
    // Generate encryption keys for this room
    // Log successful connection establishment
    // Initialize secure communication channel
  }
  
  private async validateNewParticipant(data: { participantId: string, roomId: string }) {
    // Validate participant authorization
    // Check room access permissions
    // Log participant validation
  }
}
```

### **🔐 Encryption Requirements**
```typescript
export class EncryptionEngine {
  async generateRoomKeys(roomId: string): Promise<RoomKeys> {
    // Generate AES-256 encryption key for room
    // Create key derivation for individual participants
    // Set up automatic key rotation schedule
  }
  
  async encryptRoomMessage(roomId: string, message: any): Promise<EncryptedData> {
    // Encrypt using room-specific keys
    // Include integrity verification
    // Handle key rotation transparently
  }
  
  async decryptRoomMessage(roomId: string, encrypted: EncryptedData): Promise<any> {
    // Decrypt using appropriate key version
    // Verify message integrity
    // Handle key rotation edge cases
  }
}
```

### **📋 Compliance Implementation**
```typescript
export class ComplianceManager {
  checkGDPRCompliance(data: any): ComplianceResult {
    // Data minimization check
    // Consent verification
    // Right to be forgotten compliance
    // Data portability requirements
  }
  
  checkHIPAACompliance(data: any): ComplianceResult {
    // PHI identification and protection
    // Access control verification
    // Audit trail requirements
    // Data encryption standards
  }
  
  generateComplianceReport(framework: ComplianceFramework): ComplianceReport {
    // Automated compliance status
    // Violation identification
    // Remediation recommendations
    // Audit trail summary
  }
}
```

---

## 🤖 **AI IMPLEMENTATION PROMPTS**

### **PROMPT 1: Security Foundation**
```
I need you to build the foundation for a security layer that integrates with a WebRTC SDK.

TASK: Create the basic security infrastructure and authentication system.

REQUIREMENTS:
1. Create TypeScript project structure for security module
2. Implement SecurityManager class that consumes WebRTC core events
3. Create basic AuthProvider for JWT token validation
4. Set up event subscription pattern to monitor core WebRTC events
5. Implement basic security event logging

INTEGRATION PATTERN:
The security module receives a WebRTC core instance and subscribes to its events:
- 'connection_established' → Set up secure communication
- 'participant_joined' → Validate participant authorization
- 'error_occurred' → Log security-relevant errors

INTERFACES TO IMPLEMENT:
[Include SecurityLayer interface from above]

DELIVERABLES:
- SecurityManager class with core event subscription
- AuthProvider class with JWT validation
- Basic AuditLogger for security events
- TypeScript types and configuration
- Integration with @nextrtc/core package

Focus on the foundation and integration pattern. Don't implement encryption yet.
```

### **PROMPT 2: End-to-End Encryption**
```
Building on Phase 1, now implement the encryption engine for secure communication.

TASK: Add AES-256 encryption for room-based secure messaging.

REQUIREMENTS:
1. Implement EncryptionEngine class with AES-256-GCM encryption
2. Add room-based key management (each room gets unique keys)
3. Implement key generation, rotation, and secure storage
4. Create encryptMessage() and decryptMessage() methods
5. Add key derivation for multiple participants in same room

ENCRYPTION FLOW:
- When 'connection_established' event fired → Generate room encryption keys
- When participants exchange messages → Encrypt/decrypt using room keys
- Automatic key rotation every 24 hours
- Each participant gets derived keys from master room key

PREVIOUS CODE: Build on SecurityManager foundation from Phase 1
NEW FOCUS: Cryptographic implementation, key management, secure messaging

Use Web Crypto API for all cryptographic operations. Ensure forward secrecy and perfect forward secrecy.
```

### **PROMPT 3: Compliance & Audit**
```
Add compliance frameworks and comprehensive audit logging to the security module.

TASK: Implement GDPR, HIPAA compliance checks and detailed audit trails.

REQUIREMENTS:
1. Implement ComplianceManager with GDPR and HIPAA compliance checks
2. Add comprehensive audit logging for all security events
3. Create compliance violation detection and reporting
4. Implement data retention policies and automatic cleanup
5. Add audit report generation with compliance status

COMPLIANCE FEATURES:
- GDPR: Data minimization, consent tracking, right to be forgotten
- HIPAA: PHI protection, access controls, audit requirements
- Automatic compliance monitoring and violation detection
- Secure audit log storage with integrity verification

PREVIOUS CODE: Build on Phase 1 & 2 security infrastructure
NEW FOCUS: Regulatory compliance, audit trails, violation detection

Each security event must be logged with compliance implications and retention policies applied.
```

### **PROMPT 4: Production Security & Testing**
```
Complete the security module with production-grade features and comprehensive testing.

TASK: Add advanced security features, threat detection, and full test coverage.

REQUIREMENTS:
1. Implement threat detection and anomaly monitoring
2. Add rate limiting and brute force protection
3. Create comprehensive test suite including security tests
4. Add performance optimization for encryption operations
5. Implement secure configuration validation and hardening

ADVANCED SECURITY:
- Detect unusual authentication patterns
- Monitor for compliance violations in real-time
- Implement secure key backup and recovery
- Add security headers and CSP policies
- Performance optimization for high-volume encryption

TESTING REQUIREMENTS:
- Unit tests for all cryptographic functions
- Integration tests with WebRTC core events
- Security vulnerability testing
- Compliance framework validation tests
- Performance benchmarks for encryption operations

PREVIOUS CODE: Complete security implementation from Phases 1-3
NEW FOCUS: Advanced security, threat detection, testing, optimization

This module should be production-ready with enterprise-grade security features.
```

---

# 🤖 DEVELOPER 3: AI Analytics & Performance Engine

## 📋 **Complete Specification**

### **🎯 Your Mission**
Build the AI analytics engine that predicts call quality, analyzes user behavior, and optimizes performance. You will consume network stats from WebRTC core and provide intelligent insights.

### **📦 Deliverables**
```
@nextrtc/analytics/
├── src/
│   ├── AnalyticsEngine.ts      # Main analytics orchestrator
│   ├── QualityPredictor.ts     # Network quality prediction
│   ├── ChurnPredictor.ts       # User behavior analysis
│   ├── PerformanceOptimizer.ts # Bandwidth/performance optimization
│   ├── BusinessIntelligence.ts # Revenue impact analysis
│   └── types/index.ts          # Analytics type definitions
├── dist/                       # Compiled output
├── package.json               # NPM package config
└── README.md                  # Analytics documentation
```

### **🔗 Integration Contract (CONSUME NETWORK STATS)**
```typescript
// YOU CONSUME: Events from @nextrtc/core
import { NexRTCCore, NetworkStats, ConnectionHandle } from '@nextrtc/core';

// YOU PROVIDE: AI analytics to other modules
export interface AnalyticsLayer {
  initialize(core: NexRTCCore, config: AnalyticsConfig): Promise<void>;
  predictQuality(stats: NetworkStats): QualityForecast;
  analyzeUserBehavior(userId: string, sessions: CallSession[]): BehaviorAnalysis;
  optimizeBandwidth(networkConditions: NetworkConditions): OptimizationPlan;
  calculateBusinessImpact(metrics: CallMetrics): BusinessImpact;
  generateInsights(timeRange: TimeRange): AnalyticsInsights;
}

export interface AnalyticsConfig {
  prediction: {
    enabled: boolean;
    modelType: 'simple' | 'advanced';
    predictionWindow: number; // seconds
    confidenceThreshold: number; // 0-1
  };
  businessIntelligence: {
    enabled: boolean;
    revenueTracking: boolean;
    churnPrediction: boolean;
  };
  optimization: {
    bandwidthOptimization: boolean;
    qualityAdaptation: boolean;
    costOptimization: boolean;
  };
  debug?: boolean;
}

export interface QualityForecast {
  nextMinuteQuality: QualityLevel;
  confidence: number; // 0-1
  factors: QualityFactor[];
  recommendation: QualityRecommendation;
  businessImpact: string;
}

export type QualityLevel = 'excellent' | 'good' | 'fair' | 'poor' | 'critical';

export interface QualityFactor {
  factor: string;
  impact: number; // -1 to 1
  description: string;
}

export interface BehaviorAnalysis {
  churnRisk: number; // 0-1
  engagementScore: number; // 0-1
  qualityPreference: QualityLevel;
  usagePatterns: UsagePattern[];
  recommendations: string[];
}

export interface OptimizationPlan {
  targetBandwidth: number;
  recommendedSettings: MediaSettings;
  expectedSavings: number; // percentage
  qualityImpact: number; // -1 to 1
  implementation: OptimizationStep[];
}

export interface BusinessImpact {
  revenueRisk: number; // 0-1
  customerSatisfactionScore: number; // 0-1
  churnProbability: number; // 0-1
  recommendedActions: BusinessAction[];
}
```

### **🎯 Core Event Integration (CRITICAL)**
```typescript
export class AnalyticsEngine implements AnalyticsLayer {
  private core: NexRTCCore;
  private qualityPredictor: QualityPredictor;
  private behaviorAnalyzer: BehaviorAnalyzer;
  private performanceOptimizer: PerformanceOptimizer;
  
  async initialize(core: NexRTCCore, config: AnalyticsConfig): Promise<void> {
    this.core = core;
    
    // CRITICAL: Subscribe to core events for analytics
    this.core.on('network_stats_updated', this.handleNetworkStats.bind(this));
    this.core.on('quality_changed', this.handleQualityChange.bind(this));
    this.core.on('participant_joined', this.trackUserBehavior.bind(this));
    this.core.on('participant_left', this.analyzeCallSession.bind(this));
    this.core.on('connection_established', this.startPerformanceTracking.bind(this));
  }
  
  private handleNetworkStats(data: { connectionId: string, stats: NetworkStats }) {
    // Run quality prediction algorithm
    // Check for degradation patterns
    // Update performance metrics
    // Trigger optimization if needed
  }
  
  private handleQualityChange(data: { connectionId: string, newQuality: QualityLevel, stats: NetworkStats }) {
    // Analyze quality change patterns
    // Update prediction models
    // Calculate business impact
    // Generate recommendations
  }
}
```

### **🧠 Quality Prediction Algorithm (Simple ML)**
```typescript
export class QualityPredictor {
  private readonly THRESHOLDS = {
    excellent: { rtt: 50, loss: 0.5, jitter: 10 },
    good: { rtt: 100, loss: 1.0, jitter: 20 },
    fair: { rtt: 200, loss: 3.0, jitter: 40 },
    poor: { rtt: 400, loss: 8.0, jitter: 80 }
  };
  
  predictQuality(stats: NetworkStats): QualityForecast {
    // Simple weighted scoring algorithm
    const rttScore = this.calculateRTTScore(stats.rtt);
    const lossScore = this.calculateLossScore(stats.packetLoss);
    const jitterScore = this.calculateJitterScore(stats.jitter);
    
    // Weighted combination: RTT 40%, Loss 40%, Jitter 20%
    const overallScore = (rttScore * 0.4) + (lossScore * 0.4) + (jitterScore * 0.2);
    
    return {
      nextMinuteQuality: this.scoreToQualityLevel(overallScore),
      confidence: this.calculateConfidence(stats),
      factors: this.identifyQualityFactors(stats),
      recommendation: this.generateRecommendation(overallScore),
      businessImpact: this.assessBusinessImpact(overallScore)
    };
  }
  
  private calculateRTTScore(rtt: number): number {
    // Convert RTT to 0-1 score (lower RTT = higher score)
    if (rtt <= 50) return 1.0;
    if (rtt <= 100) return 0.8;
    if (rtt <= 200) return 0.6;
    if (rtt <= 400) return 0.3;
    return 0.1;
  }
}
```

### **📊 User Behavior Analysis**
```typescript
export class ChurnPredictor {
  analyzeUserBehavior(userId: string, sessions: CallSession[]): BehaviorAnalysis {
    // Calculate behavior metrics
    const callFrequency = this.calculateCallFrequency(sessions);
    const averageQuality = this.calculateAverageQuality(sessions);
    const engagementTrend = this.calculateEngagementTrend(sessions);
    
    // Churn risk scoring
    let churnRisk = 0;
    if (callFrequency < 0.5) churnRisk += 0.3; // Low usage
    if (averageQuality < 0.6) churnRisk += 0.4; // Poor quality experience
    if (engagementTrend < 0) churnRisk += 0.3; // Declining engagement
    
    return {
      churnRisk: Math.min(churnRisk, 1.0),
      engagementScore: this.calculateEngagementScore(sessions),
      qualityPreference: this.inferQualityPreference(sessions),
      usagePatterns: this.identifyUsagePatterns(sessions),
      recommendations: this.generateRetentionRecommendations(churnRisk)
    };
  }
}
```

### **⚡ Performance Optimization**
```typescript
export class PerformanceOptimizer {
  optimizeBandwidth(conditions: NetworkConditions): OptimizationPlan {
    const availableBandwidth = conditions.estimatedBandwidth;
    const currentUsage = conditions.currentBandwidthUsage;
    
    // Optimization algorithm
    const targetReduction = this.calculateOptimalReduction(availableBandwidth, currentUsage);
    const newSettings = this.calculateOptimalSettings(targetReduction);
    
    return {
      targetBandwidth: availableBandwidth * 0.8, // Leave 20% buffer
      recommendedSettings: newSettings,
      expectedSavings: targetReduction * 100,
      qualityImpact: this.assessQualityImpact(newSettings),
      implementation: this.generateImplementationSteps(newSettings)
    };
  }
}
```

---

## 🤖 **AI IMPLEMENTATION PROMPTS**

### **PROMPT 1: Analytics Foundation**
```
I need you to build the foundation for an AI analytics engine that integrates with a WebRTC SDK.

TASK: Create the basic analytics infrastructure and quality prediction system.

REQUIREMENTS:
1. Create TypeScript project structure for analytics module
2. Implement AnalyticsEngine class that consumes WebRTC network stats
3. Create QualityPredictor with simple algorithm for network quality forecasting
4. Set up event subscription to monitor WebRTC network statistics
5. Implement basic quality scoring and prediction logic

INTEGRATION PATTERN:
The analytics module receives WebRTC core events and processes network data:
- 'network_stats_updated' → Analyze current network quality
- 'quality_changed' → Learn from quality transitions
- 'connection_established' → Start tracking session

SIMPLE ML ALGORITHM:
Use weighted scoring for quality prediction:
- RTT impact: 40% weight (lower = better)
- Packet loss: 40% weight (lower = better)  
- Jitter: 20% weight (lower = better)
- Convert to quality levels: excellent/good/fair/poor

INTERFACES TO IMPLEMENT:
[Include AnalyticsLayer interface from above]

DELIVERABLES:
- AnalyticsEngine class with event subscription
- QualityPredictor with weighted scoring algorithm
- Basic quality level classification
- TypeScript types and configuration
- Integration with @nextrtc/core package

Focus on the foundation and simple prediction algorithm. Don't implement advanced ML yet.
```

### **PROMPT 2: User Behavior Analysis**
```
Building on Phase 1, now implement user behavior analysis and churn prediction.

TASK: Add user behavior tracking and churn risk calculation.

REQUIREMENTS:
1. Implement ChurnPredictor class for user behavior analysis
2. Add call session tracking and user engagement scoring
3. Create behavior pattern detection (usage frequency, quality preferences)
4. Implement churn risk calculation based on behavior metrics
5. Add user retention recommendations

BEHAVIOR ANALYSIS ALGORITHM:
- Call frequency analysis (declining usage = churn risk)
- Quality tolerance measurement (poor quality tolerance)
- Engagement trend tracking (session duration, participation)
- Support ticket correlation (problems = churn risk)

CHURN RISK FACTORS:
- Low call frequency: +30% churn risk
- Poor quality tolerance: +40% churn risk
- Declining engagement: +30% churn risk
- Recent support tickets: +20% churn risk

PREVIOUS CODE: Build on AnalyticsEngine foundation from Phase 1
NEW FOCUS: User behavior patterns, engagement scoring, churn prediction

Track user sessions over time and identify patterns that predict user departure.
```

### **PROMPT 3: Performance Optimization**
```
Add performance optimization and bandwidth management to the analytics engine.

TASK: Implement intelligent bandwidth optimization and performance recommendations.

REQUIREMENTS:
1. Implement PerformanceOptimizer class for bandwidth optimization
2. Add network condition analysis and adaptation algorithms
3. Create cost optimization recommendations
4. Implement quality vs. bandwidth trade-off calculations
5. Add performance monitoring and bottleneck detection

OPTIMIZATION ALGORITHM:
- Analyze current bandwidth usage vs. available
