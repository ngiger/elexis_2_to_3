#!/usr/bin/env ruby

# A small helper to convert Elexis plugins from 2.1.7 to Elexis 3.0
# Copyright 2013 by Niklaus Giger <niklaus.giger@member.fsf.org>

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with this
# work for additional information regarding copyright ownership.  The ASF
# licenses this file to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
# License for the specific language governing permissions and limitations under
# the License.

require 'pp'
require 'fileutils'
require 'rexml/document'
include REXML

# configuration
ElexisCoreBundleRegexp = /ch.elexis.core(;bundle-version="[\d\.]*"|),/
ElexisBundleRegexp = /ch.elexis(;bundle-version="[\d\.]*"|),/
ElexisCoreBundles  = 'ch.elexis.core;bundle-version="3.0.0",'+
  'ch.elexis.core.data;bundle-version="3.0.0",'+
  'ch.elexis.core.ui;bundle-version="3.0.0",'+
  'ch.elexis.core.ui.icons;bundle-version="3.0.0",'
NewClassNames = {
  'ch.elexis.status.ElexisStatus' => 'ch.elexis.core.data.status.ElexisStatus',
  'ch.elexis.importers.' => 'ch.elexis.core.ui.importer.div.importers.',
  'ch.elexis.util.IOptifier' => 'ch.elexis.core.data.interfaces.IOptifier',
  'ch.elexis.util.LabeledInputField' => 'ch.elexis.core.ui.util.LabeledInputField',
  'ch.elexis.exchange' => 'ch.elexis.core.ui.exchange',
  'ch.elexis.util.ResultAdapter' => 'ch.elexis.core.data.util.ResultAdapter',
  'ch.elexis.util.IRnOutputter' => 'ch.elexis.core.data.interfaces.IRnOutputter',
  'ch.elexis.actions.LazyTreeLoader' => 'ch.elexis.core.ui.actions.LazyTreeLoader',
  'ch.elexis.ebanking_ch' => 'ch.elexis.base.ch.ebanking',
  'ch.elexis.banking.ESR' => 'ch.elexis.base.ch.ebanking.esr.ESR',
  'ch.elexis.util.FileUtility' => 'ch.elexis.core.data.util.FileUtility',
  'ch.elexis.actions.RestrictedAction' => 'ch.elexis.core.ui.actions.RestrictedAction',
  'ch.elexis.actions.ElexisEventListenerImpl'   => 'ch.elexis.core.ui.events.ElexisUiEventListenerImpl',
  'ch.elexis.core.PersistenceException' => 'ch.elexis.core.exceptions.PersistenceException',
  'ch.elexis.text.IOpaqueDocument' => 'ch.elexis.core.data.interfaces.text.IOpaqueDocument',
  'ch.elexis.preferences.PreferenceConstants' => 'ch.elexis.core.ui.constants.UiPreferenceConstants',
  'ch.elexis.preferences.inputs' => 'ch.elexis.core.ui.preferences.inputs.',
  'ch.elexis.util.PlatformHelper' => 'ch.elexis.core.data.util.PlatformHelper',
#  '' => '',
#  'ch.elexis.core.ui.views.LaborView' => '',
#  'ch.elexis.core.ui.views.DauerMediView' => '',
#  'ch.elexis.core.ui.views.PatientenListeView' => '',
  'ch.elexis.data.IVerrechenbar' => 'ch.elexis.core.data.interfaces.IVerrechenbar',
  'ch.elexis.actions.GlobalEventDispatcher;'     => 'ch.elexis.core.ui.actions.GlobalEventDispatcher;',
  'ch.elexis.actions.ObjectFilterRegistry' => 'ch.elexis.core.ui.actions.ObjectFilterRegistry',
  'ch.elexis.util.ViewMenus' => 'ch.elexis.core.ui.util.ViewMenus',
  'ch.elexis.StringConstants' => 'ch.elexis.core.constants.StringConstants',
  'ch.elexis.actions.GlobalEventDispatcher.IActivationListener' => 'ch.elexis.core.ui.actions.IActivationListener',
  'ch.elexis.actions.CodeSelectorHandler' => 'ch.elexis.core.ui.actions.CodeSelectorHandler',
  'ch.elexis.util.PersistentObject' => 'ch.elexis.core.ui.util.PersistentObject',
  'ch.elexis.actions.CodeSelectorFactory;' => 'ch.elexis.core.ui.actions.CodeSelectorFactory;',
  'ch.elexis.actions.ICodeSelectorTarget' => 'ch.elexis.core.ui.actions.ICodeSelectorTarget',
  'ch.elexis.preferences.UserSettings2' => 'ch.elexis.core.ui.contacts.preferences.UserSettings2',
  'ch.elexis.util.viewers' => 'ch.elexis.core.ui.util.viewers',
  'ch.elexis.util.ImporterPage' => 'ch.elexis.core.ui.util.ImporterPage',  
  'ch.elexis.data.IDiagnose' => 'ch.elexis.core.data.interfaces.IDiagnose',
  'ch.elexis.text.EnhancedTextField' => 'ch.elexis.core.ui.text.EnhancedTextField',
  'ch.elexis.text.IRichTextDisplay' => 'ch.elexis.core.ui.text.IRichTextDisplay',
  'ch.elexis.util.IKonsExtension' => 'ch.elexis.core.ui.util.IKonsExtension',
  'UserSettings2.setExpandedState' => 'UserSettings.setExpandedState',
#  'ch.elexis.actions.ObjectFilterRegistry.IObjectFilterProvider' => 'ch.elexis.core.ui.actions.ObjectFilterRegistry.IObjectFilterProvider',

  'ch.elexis.util.IDataAccess' => 'ch.elexis.core.data.interfaces.IDataAccess',
  'ch.elexis.views'                             => 'ch.elexis.core.ui.views',
  'ch.elexis.util.Log'                          => 'ch.elexis.core.ui.util.Log', 
  'ch.elexis.Desk'                              => 'ch.elexis.core.ui.UiDesk',
  'ch.elexis.ElexisException'                   => 'ch.elexis.core.exceptions.ElexisException',
  'ch.elexis.Hub'                               => 'ch.elexis.core.data.activator.CoreHub',
  'ch.elexis.actions.BackgroundJob'             => 'ch.elexis.core.ui.actions.BackgroundJob',
  'ch.elexis.actions.BackgroundJob'             => 'ch.elexis.core.ui.actions.BackgroundJob',
  'ch.elexis.actions.BackgroundJob.BackgroundJobListener' => 'ch.elexis.core.ui.actions.BackgroundJob.BackgroundJobListener',
  'ch.elexis.actions.ElexisEvent'               => 'ch.elexis.core.data.events.ElexisEvent',
  'ch.elexis.actions.ElexisEventDispatcher'     => 'ch.elexis.core.data.events.ElexisEventDispatcher',
  'ch.elexis.actions.ElexisEventDispatcher'     => 'ch.elexis.core.data.events.ElexisEventDispatcher',
  'ch.elexis.actions.GlobalActions'             => 'ch.elexis.core.ui.actions.GlobalActions',
  'ch.elexis.actions.Heartbeat.HeartListener'   => 'ch.elexis.core.data.events.Heartbeat.HeartListener',
  'ch.elexis.actions.JobPool'                   => 'ch.elexis.core.ui.actions.JobPool',
  'ch.elexis.core.data.IXid'                    => 'ch.elexis.core.model.IXid',
  'ch.elexis.preferences.PreferenceInitializer' => 'ch.elexis.core.data.preferences.CorePreferenceInitializer',
  'ch.elexis.preferences.SettingsPreferenceStore' => 'ch.elexis.core.ui.preferences.SettingsPreferenceStore',
  'ch.elexis.services.GlobalServiceDescriptors' => 'ch.elexis.core.data.services.GlobalServiceDescriptors',
  'ch.elexis.services.IDocumentManager'         => 'ch.elexis.core.data.services.IDocumentManager',
  'ch.elexis.text.GenericDocument'              => 'ch.elexis.core.data.services.IDocumentManager',
  'ch.elexis.text.ITextPlugin.ICallback'        => 'ch.elexis.core.ui.text.ITextPlugin.ICallback',
  'ch.elexis.text.ITextPlugin'                  => 'ch.elexis.core.ui.text.ITextPlugin',
  'ch.elexis.text.TextContainer'                => 'ch.elexis.core.ui.text.TextContainer',
  'ch.elexis.text.ReplaceCallback'              => 'ch.elexis.core.data.interfaces.text.ReplaceCallback',
  'ch.elexis.text.model.Samdas'                 => 'ch.elexis.core.text.model.Samdas',
  'ch.elexis.util.Extensions'                   => 'ch.elexis.core.data.util.Extensions',
  'ch.elexis.util.SWTHelper'                    => 'ch.elexis.core.ui.util.SWTHelper',
  }
NewExtensionPoints = {
  'point="ch.elexis.Text">' => 'point="ch.elexis.core.ui.Text">',
  'point="ch.elexis.Transporter">' => 'point="ch.elexis.core.ui.Transporter">',
  'point="ch.elexis.Diagnosecode">' => 'point="ch.elexis.core.ui.Diagnosecode">',
  'point="ch.elexis.PersistentReference">' => 'point="ch.elexis.core.data.PersistentReference">',
  'point="ch.elexis.DataAccess">' => 'point="ch.elexis.core.data.DataAccess">',
#  '' => '',
   'point="ch.elexis.KonsExtension">' => 'point="ch.elexis.core.ui.KonsExtension">',
   'point="ch.elexis.Sidebar">' => 'point="ch.elexis.core.ui.Sidebar">',
   'point="ch.elexis.ServiceRegistry">' => 'point="ch.elexis.core.ui.ServiceRegistry">',
  'point="ch.elexis.RechnungsManager"' => 'point="ch.elexis.core.ui.RechnungsManager"',
  'point="ch.elexis.Verrechnungscode">' => 'point="ch.elexis.core.ui.Verrechnungscode">,
# '' => '',
  
  }

V_2_to_3 = Struct.new("V_2_to_3", :v2, :v3) 
ReplaceByRegexp = [
  V_2_to_3.new(/(\W)Hub(\W)/,'\1CoreHub\2'),
#  V_2_to_3.new(/(\W)runInUi(\W)/ , '\1run\2'),
  V_2_to_3.new(/(\W)ElexisEventListenerImpl(\W)/ , '\1ElexisUiEventListenerImpl\2'),
  # Handle neu setImageDescriptor
  # Elexis 2.1.7: setImageDescriptor(Desk.getImageDescriptor(Desk.IMG_NEXT));
  # Elexis 3.0.0: setImageDescriptor(Images.IMG_NEXT.getImageDescriptor());
  V_2_to_3.new(/setImageDescriptor\(Desk.getImageDescriptor\(Desk([.\w]*)\)\)/ ,
    'setImageDescriptor(Images\1.getImageDescriptor())'),
  V_2_to_3.new(/setTitleImage\(Desk.getImage\(Desk([.\w]*)\)\)/ , 
    'setTitleImage(Images\1.getImage())'),
  V_2_to_3.new('CoreHub.plugin.getWorkbench()' , 'Hub.plugin.getWorkbench()'),
  V_2_to_3.new(/(\W)Desk.get'/, '\1UiDesk.get'),
  V_2_to_3.new('UserSettings2.setExpandedState', 'UserSettings.setExpandedState'),
  V_2_to_3.new(/Desk.getImage\(Desk.(\w+)\)/, 'Images.\1.getImage()'),
  V_2_to_3.new('Images.IMG_LOGO48', 'Images.IMG_LOGO'),
  V_2_to_3.new(/Desk.COL/, '\1UiDesk.COL'),
  ]

# The class manifest is borrowed from http://buildr.apache.org/
# buildr/lib/buildr/java/packaging.rb (Same license!)

class Manifest

  STANDARD_HEADER = { 'Manifest-Version'=>'1.0', 'Created-By'=>'Buildr' }
  LINE_SEPARATOR = /\r\n|\n|\r[^\n]/ #:nodoc:
  SECTION_SEPARATOR = /(#{LINE_SEPARATOR}){2}/ #:nodoc:

  # :call-seq:
  #   parse(str) => manifest
  #
  # Parse a string in MANIFEST.MF format and return a new Manifest.
  def Manifest.parse(str)
    sections = str.split(SECTION_SEPARATOR).reject { |s| s.strip.empty? }
    new sections.map { |section|
      lines = section.split(LINE_SEPARATOR).inject([]) { |merged, line|
        if line[/^ /] == ' '
          merged.last << line[1..-1]
        else
          merged << line
        end
        merged
      }
      lines.map { |line| line.scan(/(.*?):\s*(.*)/).first }.
        inject({}) { |map, (key, value)| map.merge(key=>value) }
    }
  end
  # Returns a new Manifest object based on the argument:
  # * nil         -- Empty Manifest.
  # * Hash        -- Manifest with main section using the hash name/value pairs.
  # * Array       -- Manifest with one section from each entry (must be hashes).
  # * String      -- Parse (see Manifest#parse).
  # * Proc/Method -- New Manifest from result of calling proc/method.
  def initialize(arg = nil)
    case arg
    when nil, Hash then @sections = [arg || {}]
    when Array then @sections = arg
    when String then @sections = Manifest.parse(arg).sections
    when Proc, Method then @sections = Manifest.new(arg.call).sections
    else
      fail 'Invalid manifest, expecting Hash, Array, file name/task or proc/method.'
    end
    # Add Manifest-Version and Created-By, if not specified.
    STANDARD_HEADER.each do |name, value|
      sections.first[name] ||= value
    end
  end

  # The sections of this manifest.
  attr_reader :sections

  # The main (first) section of this manifest.
  def main
    sections.first
  end

  include Enumerable

  # Iterate over each section and yield to block.
  def each(&block)
    @sections.each(&block)
  end

  # Convert to MANIFEST.MF format.
  def to_s
    @sections.map { |section|
      keys = section.keys
      keys.unshift('Name') if keys.delete('Name')
      lines = keys.map { |key| "#{key}: #{section[key]}" }
      lines + ['']
    }.flatten.join("\n")
  end

end

class Elexis_2_to_3
  def adapt_manifest
    mf_name = File.expand_path(File.join(@bundle_dir, 'META-INF', 'MANIFEST.MF'))
    content = IO.read(mf_name)
    mf = Manifest.new(content)
    mf.main['Bundle-Version'] = '3.0.0.qualifier'
    mf.main['Bundle-RequiredExecutionEnvironment'] = 'JavaSE-1.7'
    if ElexisCoreBundleRegexp.match(mf.main['Require-Bundle'])
      mf.main['Require-Bundle'] =
          mf.main['Require-Bundle'].sub(ElexisCoreBundleRegexp, ElexisCoreBundles)
    elsif ElexisBundleRegexp.match(mf.main['Require-Bundle'])
      mf.main['Require-Bundle'] =
          mf.main['Require-Bundle'].sub(ElexisBundleRegexp,ElexisCoreBundles)
    end
    mf.main['Require-Bundle'] =
        mf.main['Require-Bundle'].sub('ch.elexis.importer.div','ch.elexis.core.ui.importer.div')
    # Fix layout
    mf.main['Require-Bundle'] = mf.main['Require-Bundle'].gsub("\n",'').gsub(',', ",\n ")
    out = File.open(mf_name, 'w+')
    out.write(mf.to_s)
    out.write("\n")
    out.close
  end

  def create_file(filename, content)
    FileUtils.makedirs(File.dirname(filename)) unless File.exists?(File.dirname(filename))
    File.open(filename, 'w+') {|out|  out.write(content) }
  end

  # bin.includes\s*=\s*feature.xml in build.properties
  def addFeatureProject
    f_dir = @bundle_dir + '.feature'
    createPom(true)
    create_file(f_dir + '/build.properties', "bin.includes = feature.xml\n")
    create_file(f_dir + '/.project', 
  %(<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
  <name>#{f_dir}</name>
  <comment></comment>
  <projects>
  </projects>
  <buildSpec>
    <buildCommand>
      <name>org.eclipse.pde.FeatureBuilder</name>
      <arguments>
      </arguments>
    </buildCommand>
  </buildSpec>
  <natures>
    <nature>org.eclipse.pde.FeatureNature</nature>
  </natures>
</projectDescription>
  ))
    
    create_file(f_dir + '/feature.xml', 
  %(<?xml version="1.0" encoding="UTF-8"?>
<feature
      id="#{f_dir}"
      label="TODO: Feature for #{@bundle_dir}"
      version="3.0.0.qualifier"
      provider-name="ch.elexis">

  <description url="http://wiki.elexis.info/#{f_dir}">
      TODO: Feature for #{@bundle_dir}
  </description>

  <copyright url="http://www.example.com/copyright">
      [TODO: Enter Copyright Description here.]
  </copyright>

  <license url="http://www.example.com/license">
      [TODO: Enter License Description here.]
  </license>

  <plugin
        id="#{@bundle_dir}"
        download-size="0"
        install-size="0"
        version="0.0.0"
        unpack="false"/>

</feature>
  ))
  end

  def adaptJavaFiles
    files = Dir.glob("#{@bundle_dir}/**/*.java")
    files.each {
      |file|
    content = IO.readlines(file)
      content.each{ 
                  |line|
                  NewClassNames.each{ |v2, v3| line.gsub!(v2, v3)}
                  break if /^public class/.match(line)                                  
                  }
      content.each{ 
                  |line|
                  ReplaceByRegexp.each{ |item| line.gsub!(item.v2, item.v3) }
                  }
      File.open(file, 'w+') {|out|  out.write(content.join()) }
    }
  end

  def adaptPluginXml
    plugin_name = File.expand_path(File.join(@bundle_dir, 'plugin.xml'))
    return unless File.exists?(plugin_name)
    content = IO.readlines(plugin_name)
    content.each{ |line| NewExtensionPoints.each{ |v2, v3| line.gsub!(v2, v3)} }
    File.open(plugin_name, 'w+') {|out|  out.write(content.join()) }
  end

  def createPom(is_feature = false)
    pom_name = File.join(@bundle_dir, 'pom.xml')
    artifactId = @project_name
    test_content = nil
    if is_feature
      packaging = 'eclipse-feature'
      artifactId = @project_name+ '.feature'
      pom_name = File.join(@bundle_dir+'.feature', 'pom.xml')
    elsif @is_test_bundle
      packaging = 'eclipse-test-plugin'
      test_content = %(
  <!-- comment out to enable headless tests and add additional dependencies if needed
    -->
  <build>
    <sourceDirectory>src</sourceDirectory>
    <plugins>
      <plugin>
        <groupId>org.eclipse.tycho</groupId>
        <artifactId>tycho-surefire-plugin</artifactId>
        <version>${tycho-version}</version>
        <configuration>
          <useUIHarness>true</useUIHarness>
        </configuration>
      </plugin>
    </plugins>
  </build>
)
    else
      packaging = 'eclipse-plugin'
    end

    content = %(<project xsi:schemaLocation='http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd' xmlns='http://maven.apache.org/POM/4.0.0' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>#{@groupId}</groupId>
    <artifactId>#{@groupArtifactId}</artifactId>
    <version>#{@version}</version>
  </parent>
  <groupId>#{@groupId}</groupId>
  <artifactId>#{artifactId}</artifactId>
  <version>#{@version}</version>
  <packaging>#{packaging}</packaging>
  #{test_content}
</project>
)  
    FileUtils.makedirs(File.dirname(pom_name)) unless File.directory?(File.dirname(pom_name))
    File.open(pom_name, 'w+') {|out|  out.write(content) }
    system("git add #{@bundle_dir+'.feature'}") if is_feature
  end

  def initialize(dir)
    rootPom = File.join(Dir.pwd, 'pom.xml')
    unless File.exists?(rootPom)
      puts "Cannot continue as rootPom #{rootPoom} not found"
      exit 2
    end
    doc = REXML::Document.new(File.new(rootPom))
    @groupId = doc.root.elements['groupId'].text
    @groupArtifactId = doc.root.elements['artifactId'].text
    @version = doc.root.elements['version'].text
    @bundle_dir     = dir.chomp('/')
    @project_name   = File.basename(@bundle_dir)
    @is_test_bundle = /(test|tests)$/.match(@project_name)
    @is_feature     = /feature$/i.match(@project_name)
    system("git add #{@bundle_dir}")
  end
  
  def migrate
    createPom
    adapt_manifest
    adaptPluginXml
    addFeatureProject unless @is_test_bundle
    adaptJavaFiles
  end
end

dir = ARGV[0]
dir ||= '.'

Elexis_2_to_3.new(dir).migrate

