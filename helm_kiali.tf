resource "helm_release" "kiali-server" {
  name       = "kiali-server"
  chart      = "kiali-server"
  repository = "https://kiali.org/helm-charts"
  namespace  = "istio-system"

  create_namespace = true

  version = var.kiali_version

  set {
    name  = "server.web_fqdn"
    value = var.kiali_host
  }

  set {
    name  = "auth.strategy"
    value = "anonymous"
  }

  depends_on = [
    helm_release.istio_base,
    helm_release.istiod,
    helm_release.istio_ingress
  ]
}

resource "kubectl_manifest" "kiali_gateway" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: kiali-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway 
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - ${var.kiali_host}
YAML

  depends_on = [
    helm_release.kiali-server,
  ]

}

resource "kubectl_manifest" "kiali_virtual_service" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: kiali
  namespace: istio-system
spec:
  hosts:
  - ${var.kiali_host}
  gateways:
  - kiali-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: kiali
        port:
          number: 20001
YAML

  depends_on = [
    helm_release.kiali-server,
  ]

}