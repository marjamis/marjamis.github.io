---
title: General Docker Information
---

### Docker PID 1 and Process Reaping

**Adapted from:** [Docker and the PID 1 Zombie Reaping Problem](https://blog.phusion.nl/docker-and-the-pid-1-zombie-reaping-problem/)
If a process terminates it turns into a defunct/zombie process, which formally are:

> processes that have terminated but have not (yet) been waited for by their parent processes.

The parent process of this terminated process must explicitly "wait" for child process termination, in order to collect its exit status. The zombie process exists until the parent process has performed this action, using the waitpid() family of system calls. The action of calling waitpid() on a child process in order to eliminate its zombie, is called "reaping". When a parent process is terminated, either intentionally or some other cause, this leaves any child processes orphaned and this is when init (pid 1) will adopt the orphaned process to becomes the parent process.

This becomes an issue commonly with docker containers as the PID 1 in the container is often a process that can't perform these reaping duties, as it expects an OS init to do it, and as these zombie processes are left taking up resources without the ability to be reaped by the parent process, it can cause issues overtime.

This is where a PID 1 process within a container which can reap is important. This can be done with bash with an init process like [tini](https://github.com/krallin/tini).

## Storage Drivers

### overlay2

**More information:**

- [Overlay2 UserGuide](https://docs.docker.com/engine/storage/drivers/overlayfs-driver/)

#### General

- Filesystem based where devicemapper is block based
- To view the mounts which exist when you use the overlay storage driver with Docker, use the mount command. The output below is truncated for readability.
- As overlay2 is file based if you want the overlay2 data on a different disk you will need to provision as normal and then mount to:
  /var/lib/docker/overlay2

OverlayFS layers two directories on a single Linux host and presents them as a single directory. These directories are called layers and the unification process is referred to as a union mount. OverlayFS refers to the lower directory as lowerdir and the upper directory a upperdir. The unified view is exposed through its own directory called merged.

The lowest layer contains a file called link, which contains the name of the shortened identifier, and a directory called diff which contains the layer’s contents. The second-lowest layer, and each higher layer, contain a file called lower, which denotes its parent, and a directory called diff which contains its contents. It also contains a merged directory, which contains the unified contents of its parent layer and itself, and a work directory which is used internally by OverlayFS.

/var/lib/docker/overlay2/ # contains layers directories for an image, with a lowercase l contains shortened layer identifiers as symbolic links.

This capability provides better performance for layer-related Docker commands such as docker build and docker commit, and consumes fewer inodes on the backing filesystem.

#### New file

The file does not exist in the container layer: If a container opens a file for read access and the file does not already exist in the container (upperdir) it is read from the image (lowerdir). This incurs very little performance overhead.

The file only exists in the container layer: If a container opens a file for read access and the file exists in the container (upperdir) and not in the image (lowerdir), it is read directly from the container.

The file exists in both the container layer and the image layer: If a container opens a file for read access and the file exists in the image layer and the container layer, the file’s version in the container layer is read. Files in the container layer (upperdir) obscure files with the same name in the image layer (lowerdir).

#### Modifying files or directories

Consider some scenarios where files in a container are modified.

Writing to a file for the first time: The first time a container writes to an existing file, that file does not exist in the container (upperdir). The overlay/overlay2 driver performs a copy_up operation to copy the file from the image (lowerdir) to the container (upperdir). The container then writes the changes to the new copy of the file in the container layer.

However, OverlayFS works at the file level rather than the block level. This means that all OverlayFS copy_up operations copy the entire file, even if the\ file is very large and only a small part of it is being modified. This can have a noticeable impact on container write performance. However, two things are worth noting:

The copy_up operation only occurs the first time a given file is written to. Subsequent writes to the same file operate against the copy of the file already copied up to the container.

OverlayFS only works with two layers. This means that performance should be better than AUFS, which can suffer noticeable latencies when searching for files in images with many layers. This advantage applies to both overlay and overlay2 drivers. overlayfs2 will be slightly less performant than overlayfs on initial read, because it has to look through more layers, but it caches the results so this is only a small penalty.

#### Deleting files and directories

When a file is deleted within a container, a whiteout file is created in the container (upperdir). The version of the file in the image layer (lowerdir) is not deleted (because the lowerdir is read-only). However, the whiteout file prevents it from being available to the container.

When a directory is deleted within a container, an opaque directory is created within the container (upperdir). This works in the same way as a whiteout file and effectively prevents the directory from being accessed, even though it still exists in the image (lowerdir).

Renaming directories: Calling rename(2) for a directory is allowed only when both the source and the destination path are on the top layer. Otherwise, it returns EXDEV error (“cross-device link not permitted”). Your application needs to be designed to handle EXDEV and fall back to a “copy and unlink” strategy.

#### Benefits

- Page Caching. OverlayFS supports page cache sharing. Multiple containers accessing the same file share a single page cache entry for that file. This is good for minimising memory usage.
- copy_up. As with AUFS, OverlayFS has to perform copy-up operations whenever a container writes to a file for the first time. This can add latency into the write operation, especially for large files. However, once the file has been copied up, all subsequent writes to that file occur in the upper layer, without the need for further copy-up operations.

#### Limitations

To summarize the OverlayFS’s aspect which is incompatible with other filesystems:

- open(2): OverlayFS only implements a subset of the POSIX standards. This can result in certain OverlayFS operations breaking POSIX standards. One such operation is the copy-up operation where this can lead the file being used being a lower layer than it should be. Commonly an issue with yum requiring the yum-plugin-ovl package for yum to work with overlay2.
- rename(2): OverlayFS does not fully support the rename(2) system call. Your application needs to detect its failure and fall back to a “copy and unlink” strategy.
