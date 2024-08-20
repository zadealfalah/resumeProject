# resume_proj
 
## To Do (No particular order):
- Clean up CSS
- Add 404 html error document, update terraform website module to redirect to error document when needed
- Add db infra
- Add API infra
- Add snowplow integration
- Create BI output
- Update cloudfront to properly use HTTPS
- Add logging
- Add more pages / menu bar
- Further separate modules by logic (e.g. split 'website' into a 's3' and 'networking' module)
- Add explicit environments (dev/prod) to modules and main.tf module calls
- Reformat file references to be generic(e.g. in website/main's uploading of s3 objects)
- Update errors with GET in API Gateway
- Reformat .js file to generic URL from output of lambda/outputs.tf
- Cache busting to ensure latest content is available - can use create-invalidation in CI/CD once there.