import 'dart:io';
import 'package:cli_util/cli_logging.dart';
import 'package:get_it/get_it.dart';
import 'configuration.dart';
import 'method_extensions.dart';
import 'package:path/path.dart' as p;

/// Use the makepri.exe tool to generate package resource indexing files
class MakePri {
  final Logger _logger = GetIt.I<Logger>();
  final Configuration _config = GetIt.I<Configuration>();

  Future<void> generatePRI(List<String> displayNames) async {
    _logger.trace('generate package resource indexing files');

    final String buildPath = _config.buildFilesFolder;
    String makePriPath =
        '${_config.msixToolkitPath}/Redist.${_config.architecture}/makepri.exe';

    await _generateReswStrings(buildPath, displayNames);

    // ignore: avoid_single_cascade_in_expression_statements
    await Process.run(makePriPath, [
      'createconfig',
      '/cf',
      '$buildPath\\priconfig.xml',
      '/dq',
      'en-US',
      '/pv',
      '10.0.0',
      '/o'
    ])
      ..exitOnError();

    ProcessResult makePriProcess = await Process.run(makePriPath, [
      'new',
      '/cf',
      '$buildPath\\priconfig.xml',
      '/pr',
      buildPath,
      '/mn',
      '$buildPath\\AppxManifest.xml',
      '/of',
      '$buildPath\\resources.pri',
      '/o',
    ]);

    await File('$buildPath/priconfig.xml').deleteIfExists();

    makePriProcess.exitOnError();
  }

  Future<void> _generateReswStrings(String rootDir, List<String> names) async {
    for (var raw in names) {
      // `raw` is like `en-US=MyApp`.
      var parts = raw.split('=');
      var lang = parts[0].trim();
      var appName = parts[1].trim();

      var langDir = p.join(rootDir, 'Strings', lang);
      var reswFile = p.join(langDir, 'Resources.resw');

      await Directory(langDir).create(recursive: true);
      await File(reswFile).writeAsString(_reswAppName(appName));
    }
  }

  String _reswAppName(String localizedName) {
    return """<?xml version="1.0" encoding="utf-8"?>
<root>
  <xsd:schema id="root" xmlns="" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xsd:import namespace="http://www.w3.org/XML/1998/namespace" />
    <xsd:element name="root" msdata:IsDataSet="true">
      <xsd:complexType>
        <xsd:choice maxOccurs="unbounded">
          <xsd:element name="metadata">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="value" type="xsd:string" minOccurs="0" />
              </xsd:sequence>
              <xsd:attribute name="name" use="required" type="xsd:string" />
              <xsd:attribute name="type" type="xsd:string" />
              <xsd:attribute name="mimetype" type="xsd:string" />
              <xsd:attribute ref="xml:space" />
            </xsd:complexType>
          </xsd:element>
          <xsd:element name="assembly">
            <xsd:complexType>
              <xsd:attribute name="alias" type="xsd:string" />
              <xsd:attribute name="name" type="xsd:string" />
            </xsd:complexType>
          </xsd:element>
          <xsd:element name="data">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="value" type="xsd:string" minOccurs="0" msdata:Ordinal="1" />
                <xsd:element name="comment" type="xsd:string" minOccurs="0" msdata:Ordinal="2" />
              </xsd:sequence>
              <xsd:attribute name="name" type="xsd:string" use="required" msdata:Ordinal="1" />
              <xsd:attribute name="type" type="xsd:string" msdata:Ordinal="3" />
              <xsd:attribute name="mimetype" type="xsd:string" msdata:Ordinal="4" />
              <xsd:attribute ref="xml:space" />
            </xsd:complexType>
          </xsd:element>
          <xsd:element name="resheader">
            <xsd:complexType>
              <xsd:sequence>
                <xsd:element name="value" type="xsd:string" minOccurs="0" msdata:Ordinal="1" />
              </xsd:sequence>
              <xsd:attribute name="name" type="xsd:string" use="required" />
            </xsd:complexType>
          </xsd:element>
        </xsd:choice>
      </xsd:complexType>
    </xsd:element>
  </xsd:schema>
  <resheader name="resmimetype">
    <value>text/microsoft-resx</value>
  </resheader>
  <resheader name="version">
    <value>2.0</value>
  </resheader>
  <resheader name="reader">
    <value>System.Resources.ResXResourceReader, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
  <resheader name="writer">
    <value>System.Resources.ResXResourceWriter, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
  <data name="AppName" xml:space="preserve">
    <value>$localizedName</value>
  </data>
</root>""";
  }
}
