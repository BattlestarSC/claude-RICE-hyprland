// ASCII sky: rotating Earth and orbiting Moon drawn as characters.
//
// Pure Qt Quick (no Quickshell imports) so tests can render it outside a session
// (tests/sky/render.py). Two GPU passes:
//   1. scene.frag runs once per character cell into a cols x rows texture (color + ink density)
//   2. glyph.frag runs per pixel: cell lookup + one atlas read
// The item never animates itself: the owner feeds angles (from SkyClock), so every monitor
// shows the same instant and the frame rate is whatever the owner's timer sets.
import QtQuick

Item {
    id: root

    // Layout in logical px. Glyphs come from an atlas rendered at cellWidth x cellHeight
    // times the screen's device pixel ratio (bin/rice-sky-atlas), so they stay pixel-exact.
    property real cellWidth: 8
    property real cellHeight: 16
    property point offset: Qt.point(0, 0)         // this view's top-left in the canvas
    // Defaults frame one monitor: the Earth rises from the bottom edge, and the Moon's
    // inclined orbit (1.6 Earth radii) arcs across its face and over the limb.
    property point earthCenter: Qt.point(width * 0.5, height * 1.0)
    property real earthRadius: height * 0.55
    property real moonRadius: earthRadius * 0.27      // the real Moon/Earth ratio
    property real moonOrbit: earthRadius * 1.6

    // Animation state, radians in [0, 2pi). Provided by the owner.
    property real earthAngle: 0
    property real moonAngle: 0
    property real cloudAngle: 0
    property real twinkle: 0

    // Assets.
    property url shaderDir
    property url landMask
    property url atlas
    property int glyphs: 10

    readonly property int cols: Math.ceil(width / cellWidth)
    readonly property int rows: Math.ceil(height / cellHeight)

    ShaderEffect {
        id: scene
        width: root.cols
        height: root.rows
        blending: false

        property vector2d grid: Qt.vector2d(root.cols, root.rows)
        property vector2d cellSize: Qt.vector2d(root.cellWidth, root.cellHeight)
        property vector2d offset: Qt.vector2d(root.offset.x, root.offset.y)
        property vector2d earthCenter: Qt.vector2d(root.earthCenter.x, root.earthCenter.y)
        property real earthRadius: root.earthRadius
        property real moonRadius: root.moonRadius
        property real moonOrbit: root.moonOrbit
        property real earthAngle: root.earthAngle
        property real moonAngle: root.moonAngle
        property real cloudAngle: root.cloudAngle
        property real twinkle: root.twinkle
        property var landMask: Image { source: root.landMask; smooth: true }

        fragmentShader: root.shaderDir + "/scene.frag.qsb"
    }

    ShaderEffectSource {
        id: sceneTexture
        width: root.cols
        height: root.rows
        sourceItem: scene
        hideSource: true
        smooth: false                                  // nearest: one texel per cell
        textureSize: Qt.size(root.cols, root.rows)
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        property vector2d grid: Qt.vector2d(root.cols, root.rows)
        property real glyphs: root.glyphs
        property var scene: sceneTexture
        property var atlas: Image { source: root.atlas; smooth: true }

        fragmentShader: root.shaderDir + "/glyph.frag.qsb"
    }
}
