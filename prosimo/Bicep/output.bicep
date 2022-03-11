
param subscriptionId string

var subFormat = replace(subscriptionId, '/subscriptions/', '')

output subscriptionId string = subscriptionId
output subFormat string = subFormat
