resource "helm_release" "argocd" {

  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_fargate_profile.karpenter
  ]

}

resource "kubectl_manifest" "argocd_gateway" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: argocd
  namespace: argocd
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "${var.argocd_host}"
YAML

  depends_on = [
    helm_release.argocd,
    helm_release.istio_ingress
  ]

}

resource "kubectl_manifest" "argocd_virtual_service" {
  yaml_body = <<YAML
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: argocd
  namespace: argocd
spec:
  hosts:
  - "${var.argocd_host}"
  gateways:
  - argocd
  http:
  - route:
    - destination:
        host: argocd-server
        port:
          number: 80 
YAML

  depends_on = [
    helm_release.argocd,
    helm_release.istio_ingress
  ]

}