# GitHub Actions guidelines:

- When using a third-party action (one not hosted in a Google-managed org), a fixed version of the action MUST be used by [specifying a specific commit](https://help.github.com/en/github/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepsuses), rather than a branch like "main", or a tagged release, which can be overwritten by any maintainer of the action.
- Docker and [GitHub runner](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources) images should always be run at a fixed version rather than "latest".
- If an action is granted additional GitHub access (by being passed the GITHUB_TOKEN variable), all main development branches (typically, "main") must use [branch protection](https://help.github.com/en/github/administering-a-repository/about-protected-branches) with "Require pull request reviews before merging" enabled and/or "Restrict who can push to matching branches" limited to repository admins.

## Publishing to pub.dev

The `publish.yml` workflow publishes `tflite_core` when a `v<version>` tag is pushed. It checks that the tag matches the package version, runs formatting, analysis, tests, and a pub.dev dry run, then publishes using GitHub Actions OIDC trusted publishing. No pub.dev token is stored in GitHub secrets.

Before using the workflow:

1. Set up and verify the `kmmhanan.com` publisher on pub.dev, and make sure your account is a publisher admin.
2. Publish the first `tflite_core` version manually while signed into pub.dev, associating it with the `kmmhanan.com` publisher.
3. Open `https://pub.dev/packages/tflite_core/admin`, find **Automated publishing**, and enable publishing from GitHub Actions. Use repository `kmmhanan/tflite-core` and tag pattern `v{{version}}`.
4. Update the package version and changelog, then push a matching version tag. For example, with `version: 0.12.5` in `pubspec.yaml`, push `v0.12.5`.

The GitHub repository and tag pattern are configured on pub.dev; no workflow filename, GitHub secret, pub.dev API key, or GitHub environment is required for this workflow. See the [pub.dev automated publishing guide](https://dart.dev/tools/pub/automated-publishing).

To create a GitHub Release and trigger the publish workflow manually, run **Actions → Create release → Run workflow** on the `main` branch. It reads the version from `pubspec.yaml`, creates and pushes the corresponding `v<version>` tag, then creates a GitHub Release with generated notes. The tag push triggers `publish.yml`.

This workflow uses a repository secret named `RELEASE_TOKEN` so pushing its tag triggers other workflows (GitHub suppresses those triggers when using the default `GITHUB_TOKEN`). Create a fine-grained personal access token scoped to this repository with **Contents: Read and write**, then add it under **Settings → Secrets and variables → Actions**. The token does not authenticate to pub.dev; pub.dev publishing still uses OIDC trusted publishing. Only trusted users should be able to run this release workflow.
