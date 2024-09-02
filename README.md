![Main Branch](https://github.com/zadealfalah/resumeProject/actions/workflows/pipeline.yml/badge.svg?branch=main)
![Dev Branch](https://github.com/zadealfalah/resumeProject/actions/workflows/pipeline.yml/badge.svg?branch=dev)

# resumeProject
An online resume currently deployed on AWS via Terraform.

## Table of Contents
* [General Info](#general-info)
* [Project Goals](#project-goals)
* [To Do](#to-do)

## General Info
This project is built based off of the [cloud resume challange](https://cloudresumechallenge.dev/docs/the-challenge/aws/) with some expansion in scope.
The original goal of the challenge is to have an easily movable, cloud based resume deployed with IaC and with a proper CI/CD pipeline.  This has been
expanded to include more than just the resume allowing me to showcase other AWS skills and tools.  
My current goals for the finished product are listed [below](#project-goals):

## Project Goals
- ⬜️ Complete website with Terraform
  - ✅ Create static website w/ S3
  - ✅ Configure website with custom domain
  - ✅ Add proper permissions between resources
  - ⬜️ Configure cloudfront distribution
    - ✅ Cloudfront for hosting via Route53
    - ⬜️ Cache busting for proper updating without invalidations
  - ⬜️ Complete 'contact' page
    - ✅ Terraform for SES
    - ✅ Terraform for contact Lambda
    - ✅ Lambda creation/deployment
    - ✅ Create HTML for contact page
    - ✅ Create JS for contact page
    - ⬜️ Un-sandbox for SES permissions
  - ⬜️ Add visitor counter
    - ✅ Create visitor counter lambda
    - ✅ Create visitor counter html
    - ✅ Create visitor counter database (dynamodb)
    - ✅ Create visior counter JS
    - ⬜️ Decide where to place counter in HTML
  - ⬜️ Add logging outside of AWS cloudwatch
  - ⬜️ Add custom 404 html
    - ⬜️ Decide on layout of 404 document
  - ⬜️ Create CI/CD for website
    - ⬜️ Inside of CI/CD Take outputs of TF as inputs for python
    - ⬜️ Use IAM roles for GitHub Actions / AWS via Terraform
      - ✅ Create OIDC provider trust relationship
      - ⬜️ Scope IAM role trust to least privilege
      - ✅ Update Actions workflow file
      - ⬜️ Audit role w/ Amazon CloudTrail logs
    - ⬜️ Update pre-commit hooks
  - ⬜️ Separate Terraform modules further
    - ⬜️ Split 'website' into 's3' and 'networking'
    - ⬜️ Split 'lambda' into lambdas for each resource
  - ⬜️ Update portfolio section 
    - ⬜️ Clean up more projects to presentable state
    - ⬜️ Find more images to represent the chosen project(s)
- ⬜️ Create a BI output
  - ⬜️ Decide on tooling to use.  AWS tool, Power BI, Tableau, etc.
- ⬜️ Add snowplow integration for further analysis project

## To Do:
Below is a sort of re-hash of the above project goals with more specific notes to help me remember what needs to be done.

- Add snowplow integration
- Create BI output
- Add logging outside of AWS
- Further separate terraform modules by logic (e.g. split 'website' into a 's3' and 'networking' module)
- Add explicit environments (dev/prod) to modules and main.tf module calls
- Reformat file references to be generic(e.g. in website/main's uploading of s3 objects, .js file)
- Add tests for CI/CD (front and back end)
 - For pipeline.yml, add python version as an env variable.  Also change terraform to reference.  Can use a text file or env variable
- Update website, create images for portfolio section and small descriptions
  - Create images for portfolio section, add small descriptions of projects
  - Cache busting to ensure latest content (in CI/CD or cloudfront)
  - Add 404 html error document, update terraform to redirect to error properly
  - Change Porfolio layout to grid rather than column?
- Add Contact Form page (requires AWS request out of sandbox for proper handling, leave for later)
  - Move resources from toAdd back in once out of AWS sandbox
  - Add SES tracking/configs
  - After SES/DKIM verified, test submission form, add CORS
  - Add DB for submissions with sender/message/time, etc.