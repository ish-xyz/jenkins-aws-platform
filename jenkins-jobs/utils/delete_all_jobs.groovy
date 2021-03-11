for (job in jenkins.model.Jenkins.theInstance.getProjects()) {
    if (job.name.startsWith("job_"))  {
        job.delete()
    }
}
