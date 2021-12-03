module TestAqua

import Aqua
import BenchmarkConfigSweeps

test() = Aqua.test_all(BenchmarkConfigSweeps)

end  # module
