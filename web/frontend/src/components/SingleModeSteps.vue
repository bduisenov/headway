<template>
  <q-list>
    <q-item
      class="maneuver"
      active-class="bg-blue-1"
      v-for="maneuver in trip.valhallaRoute.legs[0].maneuvers"
      clickable
      v-on:click="clickedManeuver(maneuver)"
      v-bind:key="JSON.stringify(maneuver)"
    >
      <q-item-section avatar>
        <q-icon :name="valhallaTypeToIcon(maneuver.type)" />
      </q-item-section>
      <q-item-section>
        <q-item-label>
          {{ maneuver.instruction }}
        </q-item-label>
        <q-item-label caption>
          {{ maneuver.verbal_post_transition_instruction }}
        </q-item-label>
      </q-item-section>
    </q-item>
  </q-list>
</template>

<style lang="scss">
.maneuver {
  padding-top: 10px;
  padding-bottom: 10px;
  border-bottom: solid 1px #ddd;
}
</style>

<script lang="ts">
import Route from 'src/models/Route';
import { defineComponent, PropType } from 'vue';
import {
  ValhallaRouteLegManeuver,
  valhallaTypeToIcon,
} from 'src/services/ValhallaClient';
import { getBaseMap } from './BaseMap.vue';

export default defineComponent({
  name: 'SingleModeSteps',
  props: {
    trip: {
      type: Object as PropType<Route>,
      required: true,
    },
  },
  data(): {
    geometry: GeoJSON.LineString;
  } {
    return {
      geometry: this.trip.legs[0].geometry(),
    };
  },
  methods: {
    valhallaTypeToIcon,
    clickedManeuver: function (maneuver: ValhallaRouteLegManeuver) {
      const location = this.geometry.coordinates[maneuver.begin_shape_index];
      let coord: [number, number] = [location[0], location[1]];
      getBaseMap()?.flyTo(coord, 16);
    },
  },
});
</script>
