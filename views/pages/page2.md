# page2

text

</p>
<div x-data="{ open: false }" class="h-16">
  <button @click="open = ! open">Expand</button>
  <template x-if="open">
    <div
  x-data="{a: null}"
  x-init="a = await (await fetch('comp1')).text()"
  x-html="a"
    >
  </template>
</div>
<div
  x-data="myfun"
  x-bind="some"
>
</div>
<p class="end">
