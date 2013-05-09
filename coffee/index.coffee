template ={}

template.selectorist="""
<option value=''>Procedures</option>
{{#rows}}
<option value='{{count}}|{{name}}'>{{name}}</option>
{{/rows}}
"""

template.bottom = """
<p>{{what}} for <strong>{{key}}</strong></p>
<dl>
<dt>Cheapest</dt><dd>{{min.hospital}} in {{min.city}}, {{min.state}} at <span class="text-success">${{min.price}}</span></dd>
<dt>Most Expensive</dt><dd>{{max.hospital}} in {{max.city}}, {{max.state}} at <span class="text-error">${{max.price}}</span></dd>
<dt>Median</dt><dd>${{median}}</dd>
</dl>
"""
compiledSel = Mustache.compile template.selectorist
compiledBottom = Mustache.compile template.bottom
urlBase = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/total'
otherBase = 'https://calvin.iriscouch.com/meds/_design/medicare/_view/covered'
makeView = (what,url,id)->
	(e)->
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
		$.when($.ajax(
			url:url
			data:
				startkey:"[\"#{key}\"]"
				skip:skip
				limit:limit
				reduce:false
			dataType : "jsonp"
		).then((data)->
			if limit is 2
				outData.median = (0.5*(data.rows[0].value+data.rows[1].value)).toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
			else
				outData.median = data.rows[0].value.toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
		),$.ajax(
			url:url
			data:
				startkey:"[\"#{key}\"]"
				limit:1
				reduce:false
			dataType : "jsonp"
		).then((data)->
			outData.min = {state:data.rows[0].key[4],hospital:data.rows[0].key[2],city:data.rows[0].key[3],price:data.rows[0].key[1].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
		),$.ajax(
			url:url
			data:
				startkey:"[\"#{key}\"]"
				limit:1
				skip:count-1
				reduce:false
			dataType : "jsonp"
		).then((data)->
			outData.max = {state:data.rows[0].key[4],hospital:data.rows[0].key[2],city:data.rows[0].key[3],price:data.rows[0].key[1].toFixed(2).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")}
		)).then ()->
			$(id).html(compiledBottom(outData))
bottom = makeView("Average Total Payment",urlBase,'#totrez')
side = makeView("Average Covered Cost",otherBase,'#ctotrez')
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
	$('#totselect').html(compiledSel(out))
	$('#totselect').on 'change', bottom
	$('#totselect').on 'change', side
	true
