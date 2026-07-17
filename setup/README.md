# setup

Development setups to install our Talos module with and without litestream enabled.

You can use the following [make targets](../Makefile):

```sh
# setup k8s using kind
make setup
```

```sh
# install Talos without litestream
make run-dev
```

```sh
# install Talos with litestream
make run-dev-litestream
```