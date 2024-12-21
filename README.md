# mg-msix

Fork of [msix](https://github.com/YehudaKremer/msix) with support for localized app names.

## Usage

Replace the original msix package with this fork in `pubspec.yaml`:

```yaml
dev_dependencies:
  # msix: <version> # Remove this line.
  mg_msix:
    git:
      url: https://github.com/mgenware/mg-msix
```

In `msix_config`:

```yaml
msix_config:
  # This is the default app name field required by msix.
  # It should be the default language of your app name.
  display_name: MyApp

  # Supported languages.
  languages: en, zh-Hans

  # New field added by this fork.
  # Use this to specify localized app names.
  app_names:
    en-us: MyApp
    zh-Hans: 我的应用

  # New field added by this fork.
  # Use this to specify localized app descriptions.
  app_descriptions:
    en-us: Hello world
    zh-Hans: 你好世界

  # Other fields should be the same as the original msix package.
```

**Use `dart run mg_msix:create --store` (`mg_msix` instead of `msix`) to build.**

## Production ready?

Yes. It's being used in [my apps](https://mgenware.com/).
