import subprocess
import shutil
import os
from urllib.parse import urlparse
import hashlib
from distutils.version import LooseVersion
import re

import snakemake
from snakemake.conda import Conda
from snakemake.common import lazy_property, SNAKEMAKE_SEARCHPATH
from snakemake.exceptions import WorkflowError
from snakemake.logging import logger


SNAKEMAKE_MOUNTPOINT = "/mnt/snakemake"

class DImage:
    def __init__(self, image, dag):
        if " " in image:
            raise WorkflowError("Invalid docker image name containing "
                                "whitespace.")

        if not shutil.which("docker"):
            raise WorkflowError("The docker command has to be "
                                "available in order to use docker "
                                "integration.")
        # try:
        #     v = subprocess.check_output(["singularity", "--version"],
        #                                 stderr=subprocess.PIPE).decode()
        # except subprocess.CalledProcessError as e:
        #     raise WorkflowError(
        #         "Failed to get singularity version:\n{}".format(
        #             e.stderr.decode()))
        # v = v.rsplit(" ", 1)[-1]
        # if not LooseVersion(v) >= LooseVersion("2.4.1"):
        #     raise WorkflowError("Minimum singularity version is 2.4.1.")

        self.image = image
        #self._img_dir = dag.workflow.persistence.singularity_img_path
        # dag automatically pulls singularity images TODO

    @property
    def is_local(self):
        #scheme = urlparse(self.url).scheme
        #return not scheme or scheme == "file"
        return true

    @lazy_property
    def hash(self):
        md5hash = hashlib.md5()
        md5hash.update(self.image.encode()) # WHY ENCODE? STUDY
        return md5hash.hexdigest()

    # FIXME why do we pull here and in dag?
    def pull(self, dryrun=False):
        if self.is_local:
            return
        # TODO implement not local docker images, right now we are forced to local
        if dryrun:
            logger.info("Singularity image {} will be pulled.".format(self.url))
            return
        logger.debug("Singularity image location: {}".format(self.path))
        if not os.path.exists(self.path):
            logger.info("Pulling singularity image {}.".format(self.url))
            try:
                p = subprocess.check_output(["singularity", "pull",
                    "--name", "{}.simg".format(self.hash), self.url],
                    cwd=self._img_dir,
                    stderr=subprocess.STDOUT) # he saves images in img_dir with hash of the url as name 
            except subprocess.CalledProcessError as e:
                raise WorkflowError("Failed to pull singularity image "
                                    "from {}:\n{}".format(self.url,
                                                          e.stdout.decode()))

    @property
    def path(self):
        if self.is_local:
            #return urlparse(self.url).path # STUDY
            return self.image
        return os.path.join(self._img_dir, self.hash) + ".simg"

    def __hash__(self):
        return hash(self.hash)

    def __eq__(self, other):
        return self.image == other.image


def shellcmd(img_path, cmd, args="", envvars=None,
             shell_executable=None, container_workdir=None):
    """Execute shell command inside singularity container given optional args
       and environment variables to be passed."""

    # if img_path is given here, why do we have self.path??
    
    # I suppose this is needed for the very smart inheritance of ENVS by singularity
    # if envvars:
    #     envvars = " ".join("SINGULARITYENV_{}={}".format(k, v)
    #                        for k, v in envvars.items())
    # else:
    #     envvars = ""
    if container_workdir is not None:
        logger.error('--use-docker do not support shadow dir, TO BE IMPLEMENTED')
    # We will handle HERE occam based on an env variable to avoid code duplication 
    if shell_executable is None:
        shell_executable = "sh"
    else:
        # Ensure to just use the name of the executable, not a path,
        # because we cannot be sure where it is located in the container.
        shell_executable = os.path.split(shell_executable)[-1]

    # TODO add uid

    wd = os.getcwd() # this won't work for subworkflows? TODO
    print("*********************", wd)    
    if os.environ.get('RUN_ENV') == 'occam':
        #occam-run -v /home/egrassi:/home/egrassi  egrassi/bit_docker:small sh -c "cd /home/egrassi/bit_docker; bmake test_bmaked"
        node = os.environ.get('RUN_NODE')
        node_cmd = ""
        if node != None:
           node_cmd = "-n " + node
        args_v = re.sub('--volume','-v', args)
        # workaroud for configargparse problem with --docker-args "-v ..." with -v as a snakemake argument
        #cmd = "cd {}; ".format(wd) + cmd; not needed
        cmd = "occam-my-wait {} {} {} {} -c '{}'".format(
        node_cmd, args_v, img_path, shell_executable,
        cmd.replace("'", r"'\''"))
        #cmd = "ssh egrassi@node22 -p 22 {} {} {} -c \"{}\"".format(
        #    wd, img_path, shell_executable,
        #    cmd.replace("'", r"'\''"))
    else:
        args += " -v {}:{}".format(SNAKEMAKE_SEARCHPATH, SNAKEMAKE_MOUNTPOINT) # TODO try to remove and see what breaks
        # TODO we need to mount current dir or do we leave it to the user? user for now, need to mount whole bioinfo_root/equivalent
        args += " --user {}:{} ".format(os.getuid(), os.getgid())
        cmd = "cd {};".format(wd) + cmd;
        cmd = "docker run {} {} {} -c '{}'".format(
            args, img_path, shell_executable,
            cmd.replace("'", r"'\''"))

    logger.debug(cmd)
    return cmd

