template ={}

template.selectorist=Mustache.compile """
<option value=''>Procedures</option>
{{#rows}}
<option value='{{count}}|{{name}}'>{{name}}</option>
{{/rows}}
"""
template.title=Mustache.compile "<p>{{what}} for <strong>{{key}}</strong></p>"
template.extreams = Mustache.compile  """<strong>{{direction}}:</strong> {{hospital}} in {{city}}, {{state}} at <span class="text-{{highlight}}">${{price}}</span>"""
template.median = Mustache.compile  """<strong>Median:</strong> ${{median}}"""


reset=(clas)->
	$("#medianRow #{clas}").html('')
	$("#lowRow #{clas}").html('')
	$("#highRow #{clas}").html('')
	$("#titleRow #{clas}").html('')
urlBase = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/total'
otherBase = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/covered'
makeView = (what,url,clas)->
	(e)->
		reset(clas)
		unless e.target.value.indexOf '|' > -1
			return true
		data = e.target.value.split '|'
		count = parseInt data[0],10
		key = data[1]
		skip = Math.ceil(count / 2) - 1
		limit = 2-(count % 2)
		outData={}
		outData.key=key
		outData.what=what
		$("#titleRow #{clas}").html(template.title(outData))
		$.ajax(
			url:url
			data:
				startkey:"[\"#{key}\"]"
				skip:skip
				limit:limit
				reduce:false
			dataType : "jsonp"
		).then (data)->
			if limit is 2
				outData.median = (0.5*(data.rows[0].value+data.rows[1].value)).toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
			else
				outData.median = data.rows[0].value.toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
			$("#medianRow #{clas}").html(template.median(outData))
		
		$.ajax(
			url:url
			data:
				startkey:"[\"#{key}\"]"
				limit:1
				reduce:false
			dataType : "jsonp"
		).then (data)->
			min = {direction:'Cheapest',highlight:'success',state:data.rows[0].key[4],hospital:data.rows[0].key[2],city:data.rows[0].key[3],price:data.rows[0].key[1].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
			$("#lowRow #{clas}").html(template.extreams(min))
		
		$.ajax(
			url:url
			data:
				startkey:"[\"#{key}\"]"
				limit:1
				skip:count-1
				reduce:false
			dataType : "jsonp"
		).then (data)->
			max = {direction:'Most Expensive',highlight:'error',state:data.rows[0].key[4],hospital:data.rows[0].key[2],city:data.rows[0].key[3],price:data.rows[0].key[1].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
			$("#highRow #{clas}").html(template.extreams(max))
bottom = makeView("Average Total Payment",urlBase,'.tot')
side = makeView("Average Covered Cost",otherBase,'.covered')
$.ajax(
	url:urlBase
	data:
		group_level:1
	dataType : "jsonp"
).then (data)->
	out={}
	out.rows = for row in data.rows
		do (row)->
			ret = row.value
			ret.name = row.key[0]
			ret
	$('#totselect').html(template.selectorist(out))
	$('#totselect').on 'change', bottom
	$('#totselect').on 'change', side
	true
