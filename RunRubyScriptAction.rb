#
#  RunRubyScriptAction.rb
#  RunRubyScriptAction
#
#  Created by Jason Foreman on 12/26/07.
#  Copyright (c) 2008 Jason Foreman. All rights reserved.
#

require 'osx/cocoa'

include OSX

require_framework 'ScriptingBridge'
require 'RubyTextView'

class RunRubyScriptAction < AMBundleAction

	def typeForDescriptor(desc)
		desc[0].to_i << 24 | desc[1].to_i << 16 | desc[2].to_i << 8 | desc[3].to_i
	end

	def getSBApplication(appname)
		bundleId = LSWrapper.bundleIdentifierForApplicationWithName(appname)
		return SBApplication.applicationWithBundleIdentifier(bundleId)
	end
	
	def getObjectSource(source)
		case source.descriptorType()
		when typeForDescriptor('obj ')
			return convertObject(source)
		when typeForDescriptor('psn ')
			return getSBApplication(source.stringValue())
		end
	end
	
	def convertObject(object)
		source = getObjectSource(object.descriptorForKeyword_(typeForDescriptor("from")))
		want = object.descriptorForKeyword_(typeForDescriptor('want'))
		elements = source.elementArrayWithCode(want.typeCodeValue())
		seld = elements.objectWithID_(object.descriptorForKeyword_(typeForDescriptor('seld')).typeCodeValue())
		return seld
	end
	
	def convertInput(input)
		if input.class == NSAppleEventDescriptor then
			case input.descriptorType
			when typeForDescriptor('list')
				ret = []
				1.upto(input.numberOfItems()) do |i|
					ret << convertInput(input.descriptorAtIndex(i))
				end
				return ret
			when typeForDescriptor('obj ')
				return convertObject(input)
			else
				return input
			end
		else
			return input
		end
	end

	def runWithInput_fromAction_error(input, action, error)

		scriptSource = self.parameters['ruby script source']

		input = convertInput(input)

		klass = Class.new
		klass.class_eval(scriptSource)
		if klass.method_defined? :performAction then
			result = klass.new.performAction(input)
		else
			result = nil
		end
		
		return result
				
	end

end
