import 'dart:io';
import 'package:cli_util/cli_logging.dart';
import 'package:get_it/get_it.dart';
import 'capabilities.dart';
import 'configuration.dart';
import 'method_extensions.dart';

const localizedAppNameKey = 'ms-resource:AppName';

/// Handles the creation of the manifest file
class AppxManifest {
  final Logger _logger = GetIt.I<Logger>();
  final Configuration _config = GetIt.I<Configuration>();

  /// Generates the manifest file according to the user configuration values
  Future<void> generateAppxManifest() async {
    _logger.trace('generate appx manifest');

    String manifestContent = '''<?xml version="1.0" encoding="utf-8"?>
  <Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10" 
          xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10" 
          xmlns:uap2="http://schemas.microsoft.com/appx/manifest/uap/windows10/2" 
          xmlns:uap3="http://schemas.microsoft.com/appx/manifest/uap/windows10/3" 
          xmlns:uap4="http://schemas.microsoft.com/appx/manifest/uap/windows10/4" 
          xmlns:uap6="http://schemas.microsoft.com/appx/manifest/uap/windows10/6" 
          xmlns:uap7="http://schemas.microsoft.com/appx/manifest/uap/windows10/7" 
          xmlns:uap8="http://schemas.microsoft.com/appx/manifest/uap/windows10/8" 
          xmlns:uap10="http://schemas.microsoft.com/appx/manifest/uap/windows10/10" 
          xmlns:iot="http://schemas.microsoft.com/appx/manifest/iot/windows10" 
          xmlns:desktop="http://schemas.microsoft.com/appx/manifest/desktop/windows10" 
          xmlns:desktop2="http://schemas.microsoft.com/appx/manifest/desktop/windows10/2" 
          xmlns:desktop6="http://schemas.microsoft.com/appx/manifest/desktop/windows10/6" 
          xmlns:rescap="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities" 
          xmlns:rescap3="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities/3" 
          xmlns:rescap6="http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities/6" 
          xmlns:com="http://schemas.microsoft.com/appx/manifest/com/windows10" 
          xmlns:com2="http://schemas.microsoft.com/appx/manifest/com/windows10/2" 
          xmlns:com3="http://schemas.microsoft.com/appx/manifest/com/windows10/3" 
          IgnorableNamespaces="uap3 desktop">
    <Identity Name="${_config.identityName}" Version="${_config.msixVersion}"
              Publisher="${_config.publisher!.replaceAll(' = ', '=').toHtmlEscape()}" ProcessorArchitecture="${_config.architecture}" />
    <Properties>
      <DisplayName>$localizedAppNameKey</DisplayName>
      <PublisherDisplayName>${_config.publisherName.toHtmlEscape()}</PublisherDisplayName>
      <Logo>Images\\StoreLogo.png</Logo>
      <Description>${_config.appDescription.toHtmlEscape()}</Description>
    </Properties>
    <Resources>
      ${_config.languages!.map((language) => '<Resource Language="$language" />').join('')}
    </Resources>
    <Dependencies>
      <TargetDeviceFamily Name="Windows.Desktop" MinVersion="${_config.osMinVersion}" MaxVersionTested="10.0.22000.1" />
    </Dependencies>
    <Capabilities>
      ${_getCapabilities()}
  </Capabilities>
    <Applications>
      <Application Id="${_config.appName!.replaceAll('_', '')}" Executable="${_config.executableFileName.toHtmlEscape()}" EntryPoint="Windows.FullTrustApplication">
        <uap:VisualElements BackgroundColor="transparent"
          DisplayName="$localizedAppNameKey" Square150x150Logo="Images\\Square150x150Logo.png"
          Square44x44Logo="Images\\Square44x44Logo.png" Description="${_config.appDescription.toHtmlEscape()}">
          <uap:DefaultTile ShortName="$localizedAppNameKey" Square310x310Logo="Images\\LargeTile.png"
          Square71x71Logo="Images\\SmallTile.png" Wide310x150Logo="Images\\Wide310x150Logo.png">
            <uap:ShowNameOnTiles>
              <uap:ShowOn Tile="square150x150Logo"/>
              <uap:ShowOn Tile="square310x310Logo"/>
              <uap:ShowOn Tile="wide310x150Logo"/>
            </uap:ShowNameOnTiles>
          </uap:DefaultTile>
          <uap:SplashScreen Image="Images\\SplashScreen.png"/>
          <uap:LockScreen BadgeLogo="Images\\BadgeLogo.png" Notification="badge"/>
        </uap:VisualElements>
        ${_getExtensions()}
      </Application>
    </Applications>
  </Package>''';

    //clear empty rows
    manifestContent = manifestContent.replaceAll('    \n', '');

    String appxManifestPath = '${_config.buildFilesFolder}/AppxManifest.xml';
    await File(appxManifestPath).writeAsString(manifestContent);
  }

  String _getExtensions() {
    if (!_config.executionAlias.isNull ||
        _config.protocolActivation.isNotEmpty ||
        !_config.fileExtension.isNull ||
        !_config.toastActivatorCLSID.isNull ||
        (_config.appUriHandlerHosts != null &&
            _config.appUriHandlerHosts!.isNotEmpty) ||
        _config.enableAtStartup) {
      return '''<Extensions>
      ${!_config.executionAlias.isNull ? _getExecutionAliasExtension() : ''}
      ${_config.protocolActivation.isNotEmpty ? _getProtocolActivationExtension() : ''}
      ${!_config.fileExtension.isNull ? _getFileAssociationsExtension() : ''}
      ${!_config.toastActivatorCLSID.isNull ? _getToastNotificationActivationExtension() : ''}
      ${_config.enableAtStartup ? _getStartupTaskExtension() : ''}
      ${_config.appUriHandlerHosts != null && _config.appUriHandlerHosts!.isNotEmpty ? _getAppUriHandlerHostExtension() : ''}
        </Extensions>''';
    } else {
      return '';
    }
  }

  /// Add extension section for [_config.executionAlias]
  String _getExecutionAliasExtension() {
    return '''  <uap3:Extension Category="windows.appExecutionAlias" Executable="${_config.executableFileName.toHtmlEscape()}" EntryPoint="Windows.FullTrustApplication">
            <uap3:AppExecutionAlias>
              <desktop:ExecutionAlias Alias="${_config.executionAlias!.trim().toLowerCase().replaceAll('.exe', '').toHtmlEscape()}.exe" />
              </uap3:AppExecutionAlias>
          </uap3:Extension>''';
  }

  /// Add extension section for [_config.protocolActivation]
  String _getProtocolActivationExtension() {
    String protocolsActivation = '';
    for (String protocol in _config.protocolActivation) {
      protocolsActivation += '''
  <uap:Extension Category="windows.protocol">
            <uap:Protocol Name="${protocol.toHtmlEscape()}">
                <uap:DisplayName>${protocol.toHtmlEscape()} URI Scheme</uap:DisplayName>
            </uap:Protocol>
        </uap:Extension>''';
    }
    return protocolsActivation;
  }

  /// Add extension section for [_config.fileExtension]
  String _getFileAssociationsExtension() {
    return '''  <uap:Extension Category="windows.fileTypeAssociation">
            <uap:FileTypeAssociation Name="fileassociations">
              <uap:SupportedFileTypes>
                ${_config.fileExtension!.split(',').map((ext) => ext.trim()).map((ext) {
              return '<uap:FileType>${ext.startsWith('.') ? ext : '.$ext'}</uap:FileType>';
            }).toList().join('\n                ')}
              </uap:SupportedFileTypes>
            </uap:FileTypeAssociation>
          </uap:Extension>''';
  }

  /// Add extension section for "toast_activator" configurations
  String _getToastNotificationActivationExtension() {
    return '''  <com:Extension Category="windows.comServer">
          <com:ComServer>
            <com:ExeServer Executable="${_config.executableFileName.toHtmlEscape()}" Arguments="${_config.toastActivatorArguments.toHtmlEscape()}" DisplayName="${_config.toastActivatorDisplayName.toHtmlEscape()}">
              <com:Class Id="${_config.toastActivatorCLSID.toHtmlEscape()}"/>
            </com:ExeServer>
          </com:ComServer>
        </com:Extension>
        <desktop:Extension Category="windows.toastNotificationActivation">
          <desktop:ToastNotificationActivation ToastActivatorCLSID="${_config.toastActivatorCLSID.toHtmlEscape()}"/>
        </desktop:Extension>''';
  }

  String _getStartupTaskExtension() {
    return '''<desktop:Extension Category="windows.startupTask" Executable="${_config.executableFileName.toHtmlEscape()}" EntryPoint="Windows.FullTrustApplication">
      <desktop:StartupTask TaskId="${_config.appName!.replaceAll('_', '')}" Enabled="true" DisplayName="${_config.displayName.toHtmlEscape()}"/>
      </desktop:Extension>''';
  }

  String _getAppUriHandlerHostExtension() {
    return '''  <uap3:Extension Category="windows.appUriHandler">
            <uap3:AppUriHandler>
              ${_config.appUriHandlerHosts!.map((hostName) {
              return '<uap3:Host Name="$hostName" />';
            }).toList().join('\n                ')}
          </uap3:AppUriHandler>
          </uap3:Extension>''';
  }

  String _normalizeCapability(String capability) {
    capability = capability.trim();
    String firstLetter = capability.substring(0, 1).toLowerCase();
    return firstLetter + capability.substring(1);
  }

  /// Add capabilities section
  String _getCapabilities() {
    List<String> capabilities = _config.capabilities?.split(',') ?? [];
    capabilities.add('runFullTrust');
    capabilities = capabilities.toSet().toList();
    String capabilitiesString = '';
    const newline = '\n      ';

    capabilities
        .where((capability) => !capability.isNullOrEmpty)
        .forEach((capability) {
      capability = _normalizeCapability(capability);

      if (appCapabilities['generalUseCapabilities']!.contains(capability)) {
        capabilitiesString += '<Capability Name="$capability" />$newline';
      } else if (appCapabilities['generalUseCapabilitiesUap']!
          .contains(capability)) {
        capabilitiesString += '<uap:Capability Name="$capability" />$newline';
      } else if (appCapabilities['generalUseCapabilitiesIot']!
          .contains(capability)) {
        capabilitiesString += '<iot:Capability Name="$capability" />$newline';
      } else if (appCapabilities['generalUseCapabilitiesMobile']!
          .contains(capability)) {
        capabilitiesString +=
            '<mobile:Capability Name="$capability" />$newline';
      }
    });

    capabilities
        .where((capability) => !capability.isNullOrEmpty)
        .forEach((capability) {
      capability = _normalizeCapability(capability);

      if (appCapabilities['restrictedCapabilitiesUap']!.contains(capability)) {
        capabilitiesString += '<uap:Capability Name="$capability" />$newline';
      } else if (appCapabilities['restrictedCapabilitiesRescap']!
          .contains(capability)) {
        capabilitiesString +=
            '<rescap:Capability Name="$capability" />$newline';
      }
    });

    capabilities
        .where((capability) => !capability.isNullOrEmpty)
        .forEach((capability) {
      capability = _normalizeCapability(capability);

      if (appCapabilities['deviceCapabilities']!.contains(capability)) {
        capabilitiesString += '<DeviceCapability Name="$capability" />$newline';
      }
    });

    return capabilitiesString;
  }

  String? _getTileShortName(String? text) {
    if (text != null && text.length > 40) {
      return '${text.substring(0, 37)}...';
    }

    return text;
  }
}
