class UnitConversion

	# Contains unit conversions not available in OpenStudio.convert.
	
	# See http://nrel.github.io/OpenStudio-user-documentation/reference/measure_code_examples/
	# for available OS unit conversions. Note that this list may not be complete, so try out
	# new unit conversions before adding them here.

	def self.knots2m_s(knots)
		# knots -> m/s
		return 0.51444444*knots
	end
  
	def self.atm2Btu_ft3(atm)
		# atm -> Btu/ft^3
		return 2.719*atm
	end
	
	def self.lbm_ft32inH2O_mph2(lbm_ft3)
	    # lbm/ft^3 -> inH2O/mph^2
		return 0.01285*lbm_ft3
	end
	
	def self.lbm_fts22inH2O(lbm_fts2)
	    # lbm/(ft-s^2) -> inH2O
		return 0.005974*lbm_fts2
	end
	
	def self.lbm_ft32kg_m3(lbm_ft3)
		# lbm/ft^3 -> kg/m^3
		return 16.02*lbm_ft3
	end
	
	def self.inH2O2Pa(inH2O)
		# inH2O -> Pa
		return 249.1*inH2O
	end
  
end
