# resume_proj
 
## To Do (No particular order):
- Add 404 html error document, update terraform website module to redirect to error document when needed
- Add snowplow integration
- Create BI output
- Add logging outside of AWS
- Further separate modules by logic (e.g. split 'website' into a 's3' and 'networking' module)
- Add explicit environments (dev/prod) to modules and main.tf module calls
- Reformat file references to be generic(e.g. in website/main's uploading of s3 objects, .js file)
- Cache busting to ensure latest content is available - can use create-invalidation in CI/CD once there or add to filenames for html/js/css etc.
- Add tests for CI/CD (front and back end)
- Update website, create images for portfolio section and small descriptions
- Add SES tracking/configs
- After SES/DKIM verified, test submission form
- Add DB for submissions with sender/message/time, etc.