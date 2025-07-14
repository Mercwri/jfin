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
  for_each = {
    for dvo in aws_acm_certificate.jf_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  zone_id         = data.aws_route53_zone.mikeell.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
}

resource "aws_acm_certificate_validation" "jf_certificate" {
  certificate_arn = aws_acm_certificate.jf_certificate.arn
  validation_record_fqdns = [
    for record in aws_route53_record.jf_certificate_val : record.fqdn
  ]
}