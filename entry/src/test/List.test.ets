import localUnitTest from './LocalUnit.test'
import authModelsTest from './AuthModels.test'

export default function testsuite() {
  localUnitTest()
  authModelsTest()
}
