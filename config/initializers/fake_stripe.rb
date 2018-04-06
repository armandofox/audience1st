# Provide STRIPE_JS_HOST as an overridable constant that fake-stripe can overwrite, to avoid
# hitting Stripe's servers at all during testing.

unless defined? STRIPE_JS_HOST
  STRIPE_JS_HOST = 'https://js.stripe.com'
end
