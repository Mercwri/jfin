data "aws_route53_zone" "mikeell" {
  name         = "mikeell.com"
  private_zone = false
}

resource "aws_route53_record" "jellyfin" {
  zone_id = data.aws_route53_zone.mikeell.zone_id
  name    = "jellyfin.mikeell.com"
  type    = "A"
  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "jf_certificate" {
  domain_name       = "jellyfin.mikeell.com"
  validation_method = "DNS"
}

resource "aws_route53_record" "jf_certificate_val" {
  name    = aws_acm_certificate.jf_certificate.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.jf_certificate.domain_validation_options[0].resource_record_type
  zone_id = data.aws_route53_zone.mikeell.zone_id
  records = [aws_acm_certificate.jf_certificate.domain_validation_options[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "jf_certificate" {
  certificate_arn = aws_acm_certificate.jf_certificate.arn
  validation_record_fqdns = [
    aws_route53_record.jf_certificate_val.fqdn
  ]
}