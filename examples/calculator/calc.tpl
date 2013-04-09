<html>
<head>
    <style>
        input \{
            width: 100%;
        \}
        img \{
            cursor: pointer;
        \}
    </style>
</head>
<script>
    function add() \{
        var f = _getel('f');
        var h = _getel('h');
        h.name = 'action';
        h.value = '+';
        f.submit();
    \}
    function _getel(id) \{
        return document.getElementById(id);
    \}
</script>
<body>

<form method='post' id='f'>
<input type='hidden' name='x' id='h' value=''/>
<table border=1 cellspacing=0 cellpadding=0>
    <tr>
        <td colspan=4><input name='a' type='text' width='100%' autocomplete='off'></td>
    </tr>
    <tr>
        <td colspan=4><input name='b' type='text' width='100%' autocomplete='off'></td>
    </tr>
    <tr>
        <td align='center'>
            <!--<input type='submit' name='action' value='+'>-->
            <img src='/{$base}/static/add.png' onclick='add()'/>
        </td>
        <td>
            <input type='submit' name='action' value='-'>
        </td>
        <td>
            <input type='submit' name='action' value='*'>
        </td>
        <td>
            <input type='submit' name='action' value='/'>
        </td>
    </tr>
</table>
</form>
{$result}

</body>
</html>