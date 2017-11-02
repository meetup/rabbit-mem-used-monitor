# rabbit-mem-used-monitor
To report rabbit's memory usage
## To deploy to Prod:
    - make changes
    - load AWSPROD credentials
    - run `RABBIT_USERNAME=meetup RABBIT_PASSWORD=xxx STAGE=qa make deploy`
## To deploy to QA:
    - create a branch
    - make changes
    - load AWSQA credentials
    - run `RABBIT_USERNAME=meetup RABBIT_PASSWORD=xxx STAGE=qa make deploy`