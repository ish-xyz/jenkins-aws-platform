
for x in {1..300}; do cp jobX.groovy job_$x.groovy; sed -i.bak "s/job_X/job_$x/g" job_$x.groovy; done
