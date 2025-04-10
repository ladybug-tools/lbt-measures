# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

# see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

require 'openstudio-standards'

# start the measure
class ApplyEfficiencyStandard < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return ' Apply Efficiency Standard'
  end

  # human readable description
  def description
    return 'Apply an efficiency standard to HVAC equipment using openStudio-standards.'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Apply an efficiency standard to HVAC equipment using openStudio-standards.'
  end

  # define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for external idf
    standard = OpenStudio::Measure::OSArgument.makeStringArgument('standard', true)
    standard.setDisplayName('Standard to Apply')
    standard.setDescription('Text for the standard to be applied to the HVAC equipment. Choose from the following. DOE_Ref_Pre_1980, DOE_Ref_1980_2004, ASHRAE_2004, ASHRAE_2007, ASHRAE_2010, ASHRAE_2013, ASHRAE_2016, ASHRAE_2019')
    args << standard

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    STDOUT.flush
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # get the standard to apply
    standard_str = runner.getStringArgumentValue('standard', user_arguments)
    standard_mapper = {
      DOE_Ref_Pre_1980: 'DOE Ref Pre-1980',
      DOE_Ref_1980_2004: 'DOE Ref 1980-2004',
      ASHRAE_2004: '90.1-2004',
      ASHRAE_2007: '90.1-2007',
      ASHRAE_2010: '90.1-2010',
      ASHRAE_2013: '90.1-2013',
      ASHRAE_2016: '90.1-2016',
      ASHRAE_2019: '90.1-2019'
    }
    std_gem_standard = standard_mapper[standard_str.to_sym]
    # std_gem_standard = '90.1-2019'
    building = model.getBuilding
    building.setStandardsTemplate(std_gem_standard)
    standard_id = building.standardsTemplate.get
    standard = Standard.build(standard_id)

    # Set the heating and cooling sizing parameters
    puts 'Autosizing HVAC systems and assigning efficiencies'
    standard.model_apply_prm_sizing_parameters(model)
    # Perform a sizing run
    if standard.model_run_sizing_run(model, "#{Dir.pwd}/SR1") == false
      log_messages_to_runner(runner, debug = true)
      return false
    end
    puts 'Done with autosizing HVAC systems!'
    # If there are any multizone systems, reset damper positions
    # to achieve a 60% ventilation effectiveness minimum for the system
    # following the ventilation rate procedure from 62.1
    standard.model_apply_multizone_vav_outdoor_air_sizing(model)
    # get the climate zone  
    climate_zone_obj = model.getClimateZones.getClimateZone('ASHRAE', 2006)
    if climate_zone_obj.empty
      climate_zone_obj = model.getClimateZones.getClimateZone('ASHRAE', 2013)
    end
    climate_zone = climate_zone_obj.value
    # get the building type
    bldg_type = nil
    unless building.standardsBuildingType.empty?
      bldg_type = building.standardsBuildingType.get
    end
    # Apply the prototype HVAC assumptions
    standard.model_apply_prototype_hvac_assumptions(model, bldg_type, climate_zone)
    # Apply the HVAC efficiency standard
    standard.model_apply_hvac_efficiency_standard(model, climate_zone)
    puts 'Done with applying efficiencies!'

    return true
  end
end

# this allows the measure to be use by the application
ApplyEfficiencyStandard.new.registerWithApplication
