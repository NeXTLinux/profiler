# 🏠 Run profiler on self-hosted runners

## 0️ Setup a self-hosted runner

Learn more about hosting runners on [GitHub documentation](https://docs.github.com/en/actions/hosting-your-own-runners).

> ⚠️ To run _profiler_ on a self-hosted runner, the following dependencies needs to be installed on runner:
>
> - [docker](https://www.docker.com)
> - [jq](https://github.com/stedolan/jq)

Go to repository settings, and select `Runners` under the `Actions` side tab.

![Add a self-hosted runner](/.github/readme/imgs/setup_selfhosted_create.light.png#gh-light-mode-only)
![Add a self-hosted runner](/.github/readme/imgs/setup_selfhosted_create.dark.png#gh-dark-mode-only)

> ⚠️ Working user **must be able** to run docker. If _profiler_ is run with an unprivileged user, ensure it can open `/var/run/docker.sock`
>
> Use the following workaround when receiving the following error: `dial unix /var/run/docker.sock: connect: permission denied`
>
> ```bash
> usermod -a -G docker $USER
> chown root:docker /var/run/docker.sock
> ```

## 1️ Update workflows to use self-hosted runners

To run _profiler_ action on a self-hosted runner, uses `runs-on: self-hosted`.

_Example: render profiler for `github` organization_

```yaml
runs-on: self-hosted
steps:
  - uses: lowlighter/profiler@latest
    with:
      token: ${{ secrets.profiler_TOKEN }}
```

> 💡 To easily debug workflow errors, use [`debug: yes`](https://github.com/lowlighter/profiler/tree/master/source/plugins/core#debug) option
