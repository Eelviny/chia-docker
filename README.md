# Chia Docker

A set of Dockerfiles to run chia plotters and a farmer inside a container, with all dependencies already available. Run your plotter containers separate from your farmer, so you can update the farmer independently without stopping your plots.

**Now updated for farming in a pool! New plotting config needed, see instructions below.**

This repository is designed as a base for you to make your own configuration from; never blindly trust the code of some random person on the internet with your XCH. Fork this repo, read the scripts, understand them and customize them to your needs.

## Prerequisites

For this setup, I assume that you have a single directory for storing plots, in this guide this path is shown as `/plot-storage`. Make sure this path is replaced with the actual location that your storage drives are mounted on. Only one directory is supported - you should be using some kind of RAID/drive pooling setup. [ZFS](https://openzfs.github.io/openzfs-docs/Getting%20Started/index.html) is highly recommended, and can pool drives together to make one big volume.

A second drive is also indicated as `/scratch` - this is where the plotters will generate their plots. This should be a single fast (preferably NVMe) SSD. If you have multiple SSDs for plotting, consider putting them in RAID0 to allow for all plotters to share the resources. A performant filesystem such as XFS is good for this.

The database for the farmer will be persisted in a Docker volume - this is relatively small, and will just be stored on your boot drive.

## Setup

### Generating a keyfile

1. Create a blank file in farmer named keyfile: `touch farmer/keyfile`
2. Build the genkey image: `docker build -t localhost/chia-genkey farmer/`
3. Run command: `docker run --rm localhost/chia-genkey bash -c 'chia init && chia keys generate_and_print' | sed -n '7p' > keyfile`.
4. Copy the keyfile to the farmer directory.
5. Delete the genkey image, as it's only ever needed once: `docker image rm localhost/chia-genkey:latest`

Your keyfile should now have a newly generated key in it. **IMPORTANT: keep this key safe. It will also be embedded in your docker containers, so don't publish or share these containers publicly.**

### Starting the farmer

It can take a while for the farmer to sync, so start this before you start plotting. This container needs 2 volumes: one for the farmer database, and one shared volume where the plots are stored.

1. Build the farmer image: `docker build -t localhost/chia-farmer farmer/`
2. Create a docker volume for the database: `docker volume create chia-db`
3. Run this command to start the farmer: `docker run -it -p 8444:8444 --name farmer -v chia-db:/root/.chia -v /plot-storage:/plots:ro localhost/chia-farmer`
4. Port forward port 8444 in your router to your server.

The farmer will start up, import the keyfile to its keychain and then delete the original keyfile within the container. It will then start the farmer daemon and run a check of all your plots. You can type `CTRL+P CTRL+Q` to detach yourself from the container and leave it running in the background.

The plots directory is mounted as read-only, for safety.

### Setting up pooling

Under the hood, Chia's pooling protocol uses a smart contract and an NFT (Non fungible token). **You need to get this NFT and apply the token to the plotter to get plots compatible with pooling.** If you continue to create your plots the same way you did pre-1.2, they won't be compatible with pools.

For this example I'm using [pool.garden](https://pool.garden), but substitute the pool address with your pool of choice. Remember, you can always move your generated plots to another pool later.

1. Enter your running farmer container: `podman exec -it farmer bash`
2. Creating the NFT requires a tiny amount of XCH. Head over to https://faucet.chia.net/ and enter your wallet address (use `chia wallet get_address` to see your address) to get 100 mojo for this.
3. Create your NFT by running `chia plotnft create -u https://farm.pool.garden -s pool`
4. Wait for the transaction to complete. First you must be synced up, `chia show -s` shows your status. Type `chia plotnft show` to see the current status of your NFT creation.
5. Type `chia plotnft show | grep 'P2 singleton address' | grep -oP 'xch.+$'` to get your "P2 singleton address". Note it down for the next stage.
6. Type `chia keys show | grep 'Farmer public key' | grep -oP '(?<=: ).+$'` to get your "Farmer public key". Note it down for the next stage.

### Starting a plotter

Multiple containers of the plotter can be run in parallel. It's recommended to stagger the start times to improve efficiency. Each container will keep generating new plots for as long as it's running, and also has an useful killswitch so you can instruct the container to exit once it finishes its next plot.

1. Open the Dockerfile for the plotter. Replace `<contract address>` with your Farmer public key, and `<public key>` with your P2 singleton address. These values are not sensitive - if someone got hold of them, the worst they could do is help you by making some plots for you.
2. Build the plotter image: `docker build -t localhost/chia-plotter plotter/`
3. Start the plotter with `docker run -d --name plotter1 -v /scratch/plotter1:/tmp -v /storage/chia:/plots localhost/chia-plotter`
4. Repeat, each time with plotter2, plotter3 etc.

**IMPORTANT**: Do not use the same /tmp directory for every plotter. On startup, the plotter will delete all temporary files it sees in this folder, to cleanup from potential failed previous runs. In the above example, the /tmp folder is given a subdirectory on the scratch drive.

Alternatively, use the start-plotter bash script to start x number of plotters: `nohup bash start-plotters.sh 4 &`. Modify the script to point to the correct storage volumes first. Replace the number 4 with the number of plotters you want to start. This script will run in the background, and start each plotter every 2 hours. This staggers the start time of each plotter to maximise efficiency.

If at any time you want to stop a plotter, but don't want to lose the current plot, run this command: `docker exec plotter1 touch /root/stoprun`. Once the container finishes its current plot, it will exit instead of starting another.

## How to use

If you're following this guide I assume that you already have a good knowledge of how to manage docker, but here's a few pointers:

- Try not to attach yourself directly to the running containers. One wrong keystroke and you can accidentally terminate your plotter. Instead use `docker logs -tf plotter1` to get a live updated view of the logs, that you can view and `CTRL+C` to your heart's content.
- To check the status of your farmer, run `docker exec -it farmer bash`. This will open a new shell where you can type commands such as `chia show -sc` and `chia wallet show` without disturbing the running node.
- Viewing the logs of the farmer will give you an hourly update on the status of the node, along with your wallet balance.
- You can get the path to the logfile of each plotter using the following command: `docker inspect --format='{{.LogPath}}' plotter1`. You can use this path in external tools such as [chiaplotgraph](https://github.com/Eelviny/chia-docker/issues/6). This is untested.

## Upgrading

### Farmer

To upgrade the farmer node, it should be as simple as deleting the current running container with `docker rm -f farmer`, building the farmer container again and starting it. On startup, the container will perform any migrations necessary to the database stored in the docker volume.

If for some reason your database is corrupt, deleting the chia-db volume and creating it again will force it to make a new database.

### Plotter

Plotters are stateless, and can be deleted at any time. Stop the plotter gracefully with `docker exec plotter1 touch /root/stoprun`, wait for the current plot to finish, then delete the container. Rebuild the plotter image and start it again.

## Troubleshooting

Here's some troubleshooting steps for newcomers, based on Github issues that have come in. If you have any questions or had difficulty getting something up but found the issue, make a ticket or PR.

### My farmer is not syncing well and I have very few (if any connections)

Make sure you've forwarded port 8444 to the machine. Chia requires that the port be accessible from the internet, or you won't get any peers connecting to you.

### My farmer is not syncing but I have plenty of connections

Chia is growing fast and there [have been reports](https://github.com/Eelviny/chia-docker/issues/5) that running the farmer on a slow disk means it can't keep up with the changes in the network, causing the node to fall behind the updates and go out of sync.

This guide shows to create a Docker volume to hold your farmer, which will hold the database on your boot drive by default, but you can use a bindmount instead to place the chia-db on whichever drive you like. `docker run -it -p 8444:8444 --name farmer -v /path/to/database:/root/.chia -v /plot-storage:/plots:ro localhost/chia-farmer`
